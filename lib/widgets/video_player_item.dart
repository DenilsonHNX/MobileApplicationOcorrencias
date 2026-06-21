import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  bool _showPlayIcon = false;
  bool _paused = false;
  bool _downloading = false;
  String? _erro;

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
      _controller!.addListener(_onVideoUpdate);
      if (widget.isActive) _controller!.play();
      if (mounted) setState(() { _initialized = true; _erro = null; });
    } catch (e) {
      if (mounted) setState(() { _initialized = false; _erro = e.toString(); });
    }
  }

  void _onVideoUpdate() { if (mounted) setState(() {}); }

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
    _controller?.removeListener(_onVideoUpdate);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null) return;
    setState(() {
      _paused = !_paused;
      _showPlayIcon = true;
    });
    _paused ? _controller!.pause() : _controller!.play();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showPlayIcon = false);
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
        const SnackBar(content: Text('Inicie sessão para reagir.')));
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
        const SnackBar(content: Text('Inicie sessão para guardar.')));
      return;
    }
    try {
      final guardado = await context.read<VideoProvider>().toggleGuardar(widget.index, auth.token!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(guardado ? 'Guardado!' : 'Removido dos guardados'),
          duration: const Duration(seconds: 1),
        ));
      }
    } catch (_) {}
  }

  void _partilhar() {
    final v = widget.video;
    Share.share('${v.titulo}\n${ApiConfig.streamUrl(v.id)}', subject: v.titulo);
  }

  void _openReport() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicie sessão para denunciar.')));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => ReportDialog(videoId: widget.video.id, token: auth.token!),
    );
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final url = ApiConfig.streamUrl(widget.video.id);
      final response = await http.Request('GET', Uri.parse(url)).send();
      const downloadsPath = '/storage/emulated/0/Download';
      final downloadsDir = Directory(downloadsPath);
      if (!await downloadsDir.exists()) await downloadsDir.create(recursive: true);
      final name = widget.video.titulo
          .replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
      final file = File('$downloadsPath/${name}_${widget.video.id.substring(0, 8)}.mp4');
      final sink = file.openWrite();
      await response.stream.pipe(sink);
      await sink.close();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Download concluído: $name.mp4'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final video = context.select<VideoProvider, VideoModel>(
      (p) => p.videos.length > widget.index ? p.videos[widget.index] : widget.video,
    );

    final pos  = _controller?.value.position ?? Duration.zero;
    final dur  = _controller?.value.duration ?? Duration.zero;
    final prog = dur.inMilliseconds > 0
        ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Vídeo / thumbnail ────────────────────────────────
        GestureDetector(
          onTap: _togglePlay,
          child: _initialized && _controller != null
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              : _buildThumbnail(video),
        ),

        // ── Gradiente ────────────────────────────────────────
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xCC000000), Colors.transparent],
                stops: [0.0, 0.55],
              ),
            ),
          ),
        ),

        // ── Ícone play/pause central ─────────────────────────
        if (_showPlayIcon)
          IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                opacity: _showPlayIcon ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(140),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _paused ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),

        // ── Loading / erro ───────────────────────────────────
        if (!_initialized)
          IgnorePointer(
            child: Center(
              child: _erro != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_erro!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                          textAlign: TextAlign.center),
                    )
                  : const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
          ),

        // ── Info inferior esquerdo ───────────────────────────
        Positioned(
          bottom: 56,
          left: 14,
          right: 68,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('@${video.nomeAutor}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                    )),
                const SizedBox(height: 3),
                Text(video.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (video.categoriaNome != null) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withAlpha(180),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(video.categoriaNome!,
                        style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── Botões de acção (direita) ────────────────────────
        Positioned(
          bottom: 56,
          right: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Btn(
                icon: video.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: _fmt(video.likes),
                color: video.isLiked ? Colors.redAccent : Colors.white,
                onTap: _toggleLike,
              ),
              _Btn(
                icon: Icons.chat_bubble_rounded,
                label: _fmt(video.comentarios),
                color: Colors.white,
                onTap: _openComments,
              ),
              _Btn(
                icon: video.isGuardado ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                label: 'Guardar',
                color: video.isGuardado ? Colors.blueAccent : Colors.white,
                onTap: _toggleGuardar,
              ),
              _Btn(
                icon: Icons.share_rounded,
                label: 'Partilhar',
                color: Colors.white,
                onTap: _partilhar,
              ),
              _Btn(
                icon: Icons.flag_outlined,
                label: 'Denúncia',
                color: Colors.white60,
                onTap: _openReport,
              ),
              if (_downloading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                )
              else
                _Btn(
                  icon: Icons.download_rounded,
                  label: 'Download',
                  color: Colors.white,
                  onTap: _download,
                ),
            ],
          ),
        ),

        // ── Barra de progresso (timeline) ────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {}, // impede que o tap propague para _togglePlay
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              color: Colors.transparent,
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  return GestureDetector(
                    onTapDown: (d) {
                      if (!_initialized || _controller == null) return;
                      final ratio = (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                      _controller!.seekTo(Duration(
                          milliseconds: (ratio * dur.inMilliseconds).round()));
                    },
                    onHorizontalDragUpdate: (d) {
                      if (!_initialized || _controller == null) return;
                      final ratio = (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                      _controller!.seekTo(Duration(
                          milliseconds: (ratio * dur.inMilliseconds).round()));
                    },
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Track de fundo
                        Container(height: 3, decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        )),
                        // Track progresso
                        FractionallySizedBox(
                          widthFactor: prog,
                          child: Container(height: 3, decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(2),
                          )),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail(VideoModel video) {
    if (video.fullThumbnailUrl != null) {
      return Image.network(video.fullThumbnailUrl!, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() => const ColoredBox(
    color: Colors.black,
    child: Center(child: Icon(Icons.videocam_off_outlined, color: Colors.white24, size: 40)),
  );
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Btn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26,
                shadows: const [Shadow(blurRadius: 4, color: Colors.black54)]),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
                )),
          ],
        ),
      ),
    );
  }
}
