import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../config/api_config.dart';
import '../../models/video_model.dart';
import '../../services/video_service.dart';

class VideoDetailScreen extends StatefulWidget {
  final VideoModel video;

  const VideoDetailScreen({super.key, required this.video});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    // Tentar obter URL completo via detalhe do vídeo
    VideoModel video = widget.video;
    try {
      video = await VideoService.getVideo(widget.video.id);
    } catch (_) {}

    final url = video.fullStreamUrl;
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _ctrl!.initialize();
      _ctrl!.setLooping(true);
      _ctrl!.play();
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _initialized = false);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_ctrl == null) return;
    setState(() => _paused = !_paused);
    _paused ? _ctrl!.pause() : _ctrl!.play();
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

  @override
  Widget build(BuildContext context) {
    final video = widget.video;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'Partilhar',
            onPressed: _partilhar,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: _togglePlay,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_initialized && _ctrl != null)
              FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _ctrl!.value.size.width,
                  height: _ctrl!.value.size.height,
                  child: VideoPlayer(_ctrl!),
                ),
              )
            else if (video.fullThumbnailUrl != null)
              Image.network(video.fullThumbnailUrl!, fit: BoxFit.contain)
            else
              const Center(child: CircularProgressIndicator(color: Colors.white)),

            if (!_initialized)
              const Center(child: CircularProgressIndicator(color: Colors.white)),

            if (_paused)
              const Center(
                child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 72),
              ),

            // Informações do vídeo na parte inferior
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '@${video.nomeAutor}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.titulo,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    if (video.descricao.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        video.descricao,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.favorite_border, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text('${video.likes}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(width: 16),
                        const Icon(Icons.remove_red_eye_outlined, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text('${video.visualizacoes}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        if (video.categoriaNome != null) ...[
                          const SizedBox(width: 16),
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
