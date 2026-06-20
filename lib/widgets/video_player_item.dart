import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/video_model.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../providers/video_provider.dart';
import 'comments_sheet.dart';
import 'report_dialog.dart';

class VideoPlayerItem extends StatefulWidget {
  final VideoModel video;
  final int index;
  final bool isActive;

  const VideoPlayerItem({
    super.key,
    required this.video,
    required this.index,
    required this.isActive,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _showControls = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final url = widget.video.fullStreamUrl;
    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _controller!.initialize();
      _controller!.setLooping(true);
      if (widget.isActive) _controller!.play();
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _initialized = false);
    }
  }

  @override
  void didUpdateWidget(VideoPlayerItem old) {
    super.didUpdateWidget(old);
    if (old.isActive != widget.isActive) {
      if (widget.isActive) {
        _controller?.play();
        context.read<VideoProvider>().incrementarVisualizacoes(widget.index);
      } else {
        _controller?.pause();
        _paused = false;
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null) return;
    setState(() {
      _paused = !_paused;
      _showControls = true;
    });
    if (_paused) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _openComments() {
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, sc) => CommentsSheet(
          videoId: widget.video.id,
          token: auth.token,
          onCommentAdded: () =>
              context.read<VideoProvider>().incrementarComentarios(widget.index),
        ),
      ),
    );
  }

  Future<void> _toggleLike() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicie sessão para reagir ao vídeo.')),
      );
      return;
    }
    try {
      await context.read<VideoProvider>().toggleLike(widget.index, auth.token!);
    } catch (_) {}
  }

  Future<void> _toggleGuardar() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicie sessão para guardar vídeos.')),
      );
      return;
    }
    try {
      final guardado = await context.read<VideoProvider>().toggleGuardar(widget.index, auth.token!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(guardado ? 'Vídeo guardado!' : 'Removido dos guardados'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {}
  }

  void _partilhar() {
    final video = widget.video;
    final link = ApiConfig.streamUrl(video.id);
    Share.share(
      'Vê esta ocorrência na plataforma OcorrênciasApp!\n\n'
      '${video.titulo}\n${video.descricao}\n\n$link',
      subject: video.titulo,
    );
  }

  void _openReport() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicie sessão para denunciar.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => ReportDialog(videoId: widget.video.id, token: auth.token!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final video = context.select<VideoProvider, VideoModel>(
      (p) => p.videos.length > widget.index ? p.videos[widget.index] : widget.video,
    );

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Vídeo ou thumbnail
          if (_initialized && _controller != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            _buildThumbnail(video),

          // Gradiente inferior
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
          ),

          // Ícone de play/pausa
          if (_showControls)
            Center(
              child: AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                  child: Icon(
                    _paused ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),

          // Carregando
          if (!_initialized)
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Informações do vídeo (inferior esquerdo)
          Positioned(
            bottom: 80,
            left: 16,
            right: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${video.nomeAutor}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  video.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (video.categoriaNome != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      video.categoriaNome!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
                if (video.localizacao != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 14),
                      Text(
                        '${video.localizacao!['latitude']?.toStringAsFixed(4)}, '
                        '${video.localizacao!['longitude']?.toStringAsFixed(4)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Botões de ação (direita)
          Positioned(
            bottom: 80,
            right: 8,
            child: Column(
              children: [
                _ActionButton(
                  icon: video.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  label: _formatCount(video.likes),
                  color: video.isLiked ? Colors.red : Colors.white,
                  onTap: _toggleLike,
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.comment_rounded,
                  label: _formatCount(video.comentarios),
                  color: Colors.white,
                  onTap: _openComments,
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.remove_red_eye_rounded,
                  label: _formatCount(video.visualizacoes),
                  color: Colors.white,
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: video.isGuardado ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  label: 'Guardar',
                  color: video.isGuardado ? Colors.blueAccent : Colors.white,
                  onTap: _toggleGuardar,
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.share_rounded,
                  label: 'Partilhar',
                  color: Colors.white,
                  onTap: _partilhar,
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.flag_rounded,
                  label: 'Denunciar',
                  color: Colors.white70,
                  onTap: _openReport,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(VideoModel video) {
    if (video.fullThumbnailUrl != null) {
      return Image.network(
        video.fullThumbnailUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _blackBackground(),
      );
    }
    return _blackBackground();
  }

  Widget _blackBackground() => Container(
        color: Colors.black,
        child: const Center(child: Icon(Icons.videocam_off_outlined, color: Colors.white24, size: 48)),
      );

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32, shadows: const [Shadow(blurRadius: 4, color: Colors.black)]),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
            ),
          ),
        ],
      ),
    );
  }
}
