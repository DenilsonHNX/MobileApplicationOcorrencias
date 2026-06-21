import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  bool _showControls = true;
  bool _downloading = false;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    VideoModel video = widget.video;
    try {
      video = await VideoService.getVideo(widget.video.id);
    } catch (_) {}

    final url = video.fullStreamUrl;
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _ctrl!.initialize();
      _ctrl!.setLooping(false);
      _ctrl!.setVolume(_volume);
      _ctrl!.play();
      _ctrl!.addListener(() { if (mounted) setState(() {}); });
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
    _ctrl!.value.isPlaying ? _ctrl!.pause() : _ctrl!.play();
    setState(() {});
  }

  void _stop() {
    _ctrl?.pause();
    _ctrl?.seekTo(Duration.zero);
    setState(() {});
  }

  void _seek(int seconds) {
    if (_ctrl == null) return;
    final pos = _ctrl!.value.position + Duration(seconds: seconds);
    final dur = _ctrl!.value.duration;
    _ctrl!.seekTo(pos < Duration.zero ? Duration.zero : (pos > dur ? dur : pos));
  }

  void _setVolume(double v) {
    setState(() => _volume = v);
    _ctrl?.setVolume(v);
  }

  void _toggleControls() => setState(() => _showControls = !_showControls);

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final url = ApiConfig.streamUrl(widget.video.id);
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();

      // Pasta Downloads pública do Android (/storage/emulated/0/Download/)
      const downloadsPath = '/storage/emulated/0/Download';
      final dir = Directory(downloadsPath);
      if (!await dir.exists()) await dir.create(recursive: true);
      final safeName = widget.video.titulo
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(' ', '_');
      final filePath = '$downloadsPath/${safeName}_${widget.video.id.substring(0, 8)}.mp4';

      final file = File(filePath);
      final sink = file.openWrite();
      await response.stream.pipe(sink);
      await sink.close();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download concluído: $safeName.mp4'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no download: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _partilhar() {
    Share.share(
      'Vê esta ocorrência!\n\n${widget.video.titulo}\n${ApiConfig.streamUrl(widget.video.id)}',
      subject: widget.video.titulo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final pos = _ctrl?.value.position ?? Duration.zero;
    final dur = _ctrl?.value.duration ?? Duration.zero;
    final progress = dur.inMilliseconds > 0
        ? pos.inMilliseconds / dur.inMilliseconds
        : 0.0;
    final isPlaying = _ctrl?.value.isPlaying ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Partilhar',
            onPressed: _partilhar,
          ),
          _downloading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download_rounded),
                  tooltip: 'Download',
                  onPressed: _download,
                ),
        ],
      ),
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Player ──────────────────────────────────────────
            if (_initialized && _ctrl != null)
              Center(
                child: AspectRatio(
                  aspectRatio: _ctrl!.value.aspectRatio,
                  child: VideoPlayer(_ctrl!),
                ),
              )
            else if (video.fullThumbnailUrl != null)
              Image.network(video.fullThumbnailUrl!, fit: BoxFit.contain)
            else
              const Center(child: CircularProgressIndicator(color: Colors.white)),

            if (!_initialized)
              const Center(child: CircularProgressIndicator(color: Colors.white)),

            // ── Controlos + info ─────────────────────────────────
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Gradiente de fundo
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black, Colors.transparent],
                          stops: [0.0, 1.0],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info
                          Text('@${video.nomeAutor}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(video.titulo,
                              style: const TextStyle(color: Colors.white, fontSize: 14)),
                          if (video.descricao.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(video.descricao,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 12),

                          // ── Barra de progresso ───────────────
                          Row(
                            children: [
                              Text(_fmt(pos),
                                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                    activeTrackColor: Colors.blueAccent,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.white,
                                    overlayColor: Colors.blueAccent.withAlpha(40),
                                  ),
                                  child: Slider(
                                    value: progress.clamp(0.0, 1.0),
                                    onChanged: _initialized
                                        ? (v) => _ctrl!.seekTo(Duration(
                                            milliseconds: (v * dur.inMilliseconds).round()))
                                        : null,
                                  ),
                                ),
                              ),
                              Text(_fmt(dur),
                                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),

                          // ── Botões de controlo ───────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Stop
                              IconButton(
                                icon: const Icon(Icons.stop_rounded, color: Colors.white70),
                                tooltip: 'Stop',
                                onPressed: _initialized ? _stop : null,
                              ),
                              // Recuar 10s
                              IconButton(
                                icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                                iconSize: 32,
                                tooltip: 'Recuar 10s',
                                onPressed: _initialized ? () => _seek(-10) : null,
                              ),
                              // Play / Pause
                              Container(
                                width: 52, height: 52,
                                decoration: const BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                  ),
                                  iconSize: 30,
                                  tooltip: isPlaying ? 'Pause' : 'Play',
                                  onPressed: _initialized ? _togglePlay : null,
                                ),
                              ),
                              // Avançar 10s
                              IconButton(
                                icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                                iconSize: 32,
                                tooltip: 'Avançar 10s',
                                onPressed: _initialized ? () => _seek(10) : null,
                              ),
                              // Volume
                              PopupMenuButton<double>(
                                icon: Icon(
                                  _volume == 0 ? Icons.volume_off_rounded
                                      : _volume < 0.5 ? Icons.volume_down_rounded
                                      : Icons.volume_up_rounded,
                                  color: Colors.white70,
                                ),
                                tooltip: 'Volume',
                                color: Colors.grey.shade900,
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    enabled: false,
                                    child: SizedBox(
                                      width: 160,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Volume ${(_volume * 100).round()}%',
                                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                          Slider(
                                            value: _volume,
                                            onChanged: _setVolume,
                                            activeColor: Colors.blueAccent,
                                            inactiveColor: Colors.white24,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
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
