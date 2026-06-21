import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/video_model.dart';
import '../video/video_detail_screen.dart';

class VideoGrid extends StatelessWidget {
  final List<VideoModel> videos;
  const VideoGrid({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 9 / 16,
      ),
      itemCount: videos.length,
      itemBuilder: (ctx, i) {
        final video = videos[i];
        return GestureDetector(
          onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => VideoDetailScreen(video: video)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (video.fullThumbnailUrl != null)
                CachedNetworkImage(
                  imageUrl: video.fullThumbnailUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => _placeholder(),
                )
              else
                _placeholder(),
              // Ícone de play central
              const Center(
                child: Icon(
                  Icons.play_circle_filled_rounded,
                  color: Colors.white54,
                  size: 36,
                ),
              ),
              // Gradient + duração
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        _formatDuracao(video.duracao),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF1A1A2E),
        child: const Center(
          child: Icon(Icons.videocam_rounded, color: Colors.white24, size: 28),
        ),
      );

  String _formatDuracao(double s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final seg = (s % 60).toInt().toString().padLeft(2, '0');
    return '$m:$seg';
  }
}

class EmptyVideoState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;

  const EmptyVideoState({super.key, required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.white24),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(sub,
                style: const TextStyle(color: Colors.white38, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
