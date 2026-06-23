import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/live_service.dart';

// ─────────────────────────── VIEWER ──────────────────────────────────────────

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  bool _aoVivo        = false;
  String? _titulo;
  String? _iniciadoEm;
  bool _verificando   = true;

  VideoPlayerController? _controller;
  bool _playerReady   = false;
  String? _erroPlayer;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _verificarStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _verificarStatus());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _verificarStatus() async {
    try {
      final uri = Uri.parse('${ApiConfig.mediaBaseUrl}/api/live/status');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final aoVivo = data['ao_vivo'] == true;

      if (aoVivo && !_aoVivo) {
        setState(() {
          _aoVivo     = true;
          _titulo     = data['titulo'] as String?;
          _iniciadoEm = data['iniciadoEm'] as String?;
          _verificando = false;
        });
        await _iniciarPlayer();
      } else if (!aoVivo && _aoVivo) {
        _controller?.dispose();
        setState(() {
          _aoVivo      = false;
          _playerReady = false;
          _controller  = null;
          _erroPlayer  = null;
          _verificando = false;
        });
      } else {
        setState(() {
          _aoVivo      = aoVivo;
          _titulo      = data['titulo'] as String?;
          _iniciadoEm  = data['iniciadoEm'] as String?;
          _verificando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _verificando = false);
    }
  }

  Future<void> _iniciarPlayer() async {
    final hlsUrl = '${ApiConfig.mediaBaseUrl}/hls/live/index.m3u8';
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(hlsUrl));
    try {
      await ctrl.initialize();
      await ctrl.play();
      if (!mounted) { ctrl.dispose(); return; }
      setState(() { _controller = ctrl; _playerReady = true; _erroPlayer = null; });
    } catch (e) {
      ctrl.dispose();
      if (mounted) setState(() { _erroPlayer = e.toString(); _playerReady = false; });
    }
  }

  String _fmtHora(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  void _abrirBroadcaster() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1F),
        elevation: 0,
        title: Row(children: [
          if (_aoVivo) ...[
            Container(width: 10, height: 10,
              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            const Text('AO VIVO', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          ] else
            const Text('Transmissão', style: TextStyle(color: Colors.white70, fontSize: 16)),
        ]),
        actions: [
          if (auth.isAuthenticated)
            TextButton.icon(
              icon: const Icon(Icons.videocam_rounded, color: Colors.redAccent, size: 20),
              label: const Text('Ir ao Vivo', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onPressed: _abrirBroadcaster,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: () { setState(() => _verificando = true); _verificarStatus(); },
          ),
        ],
      ),
      body: _verificando
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _aoVivo
              ? _buildPlayer()
              : _buildOffline(auth),
    );
  }

  Widget _buildPlayer() {
    return Column(children: [
      Container(
        color: const Color(0xFF0D0D1F),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
            child: const Text('🔴 AO VIVO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_titulo ?? 'Transmissão ao Vivo',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
          ),
          if (_iniciadoEm != null)
            Text('desde ${_fmtHora(_iniciadoEm)}',
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ),
      Expanded(
        child: _playerReady && _controller != null
            ? _buildVideoControls()
            : _erroPlayer != null
                ? _buildErroPlayer()
                : const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.redAccent),
                      SizedBox(height: 16),
                      Text('A ligar ao stream...', style: TextStyle(color: Colors.white54)),
                    ],
                  )),
      ),
    ]);
  }

  Widget _buildVideoControls() {
    final ctrl = _controller!;
    return Column(children: [
      AspectRatio(
        aspectRatio: ctrl.value.aspectRatio > 0 ? ctrl.value.aspectRatio : 16 / 9,
        child: VideoPlayer(ctrl),
      ),
      Container(
        color: const Color(0xFF0D0D1F),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(children: [
          VideoProgressIndicator(ctrl, allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.redAccent, bufferedColor: Colors.white24, backgroundColor: Colors.white12)),
          const SizedBox(height: 6),
          Row(children: [
            ValueListenableBuilder(
              valueListenable: ctrl,
              builder: (_, v, child) => IconButton(
                icon: Icon(v.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                onPressed: () => v.isPlaying ? ctrl.pause() : ctrl.play(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.replay_10_rounded, color: Colors.white70),
              onPressed: () {
                final pos = ctrl.value.position - const Duration(seconds: 10);
                ctrl.seekTo(pos < Duration.zero ? Duration.zero : pos);
              },
            ),
            IconButton(
              icon: const Icon(Icons.forward_10_rounded, color: Colors.white70),
              onPressed: () => ctrl.seekTo(ctrl.value.position + const Duration(seconds: 10)),
            ),
            const Spacer(),
            ValueListenableBuilder(
              valueListenable: ctrl,
              builder: (_, v, child) => IconButton(
                icon: Icon(v.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white70),
                onPressed: () => ctrl.setVolume(v.volume == 0 ? 1.0 : 0.0),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: ctrl,
              builder: (_, v, child) {
                String fmt(Duration d) =>
                    '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
                return Text('${fmt(v.position)} / ${fmt(v.duration)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11));
              },
            ),
            const SizedBox(width: 8),
          ]),
        ]),
      ),
    ]);
  }

  Widget _buildErroPlayer() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.signal_wifi_bad_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          const Text('Erro ao ligar ao stream', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 8),
          Text(_erroPlayer ?? '', style: const TextStyle(color: Colors.white38, fontSize: 11), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
            onPressed: _iniciarPlayer,
          ),
        ]),
      ),
    );
  }

  Widget _buildOffline(AuthProvider auth) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: const Icon(Icons.sensors_off_rounded, color: Colors.white24, size: 40),
          ),
          const SizedBox(height: 24),
          const Text('Sem transmissão activa',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Nenhuma transmissão ao vivo de momento.',
            style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center),
          const SizedBox(height: 32),
          if (auth.isAuthenticated) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.videocam_rounded),
              label: const Text('Iniciar Transmissão', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _abrirBroadcaster,
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white54,
              side: const BorderSide(color: Colors.white24),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Verificar novamente'),
            onPressed: () { setState(() => _verificando = true); _verificarStatus(); },
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────── BROADCASTER ─────────────────────────────────────

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  CameraController? _camCtrl;
  List<CameraDescription> _cameras = [];
  bool _iniciando   = true;
  bool _transmitindo = false;
  bool _parando        = false;
  bool _trocandoCamera = false;
  String? _erro;
  int _chunksEnviados = 0;
  String _titulo = 'Transmissão ao Vivo';

  Timer? _chunkTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _chunkTimer?.cancel();
    _camCtrl?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception('Nenhuma câmara encontrada.');
      final camBackIdx = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      final cam = _cameras[camBackIdx >= 0 ? camBackIdx : 0];
      final ctrl = CameraController(cam, ResolutionPreset.medium, enableAudio: true);
      await ctrl.initialize();
      if (!mounted) return;
      setState(() { _camCtrl = ctrl; _iniciando = false; });
    } catch (e) {
      if (mounted) setState(() { _erro = e.toString(); _iniciando = false; });
    }
  }

  Future<void> _iniciarTransmissao() async {
    if (_camCtrl == null || _transmitindo) return;
    setState(() { _transmitindo = true; _chunksEnviados = 0; });

    final token = context.read<AuthProvider>().token;
    await _gravarEEnviarChunk(token, titulo: _titulo);

    // Chunk a cada 2 segundos
    _chunkTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_transmitindo) await _gravarEEnviarChunk(token);
    });
  }

  Future<void> _gravarEEnviarChunk(String? token, {String? titulo}) async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    try {
      await _camCtrl!.startVideoRecording();
      await Future.delayed(const Duration(seconds: 2));
      if (!_transmitindo) {
        await _camCtrl!.stopVideoRecording();
        return;
      }
      final file = await _camCtrl!.stopVideoRecording();
      if (!mounted) return;
      setState(() => _chunksEnviados++);
      // Enviar em background — não bloqueia o próximo chunk
      LiveService.uploadChunk(file.path, token: token, titulo: titulo).then((_) {
        try { File(file.path).deleteSync(); } catch (_) {}
      }).catchError((_) {});
    } catch (e) {
      // Continua mesmo com erros pontuais
      debugPrint('Chunk error: $e');
    }
  }

  Future<void> _pararTransmissao() async {
    setState(() => _parando = true);
    _chunkTimer?.cancel();
    _chunkTimer = null;

    // Capturar token antes dos awaits
    final token = context.read<AuthProvider>().token;

    try {
      if (_camCtrl?.value.isRecordingVideo == true) {
        final file = await _camCtrl!.stopVideoRecording();
        await LiveService.uploadChunk(file.path, token: token);
        try { File(file.path).deleteSync(); } catch (_) {}
      }
    } catch (_) {}

    try {
      await LiveService.stopCameraLive(token: token);
    } catch (_) {}

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _iniciando
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : _erro != null
              ? _buildErro()
              : _buildBroadcaster(),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.videocam_off_rounded, color: Colors.redAccent, size: 56),
          const SizedBox(height: 16),
          const Text('Erro ao aceder à câmara', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 8),
          Text(_erro!, style: const TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
        ]),
      ),
    );
  }

  Widget _buildBroadcaster() {
    return Stack(fit: StackFit.expand, children: [
      // Preview câmara
      if (_camCtrl != null) CameraPreview(_camCtrl!),

      // Overlay escuro no topo e base
      Positioned(
        top: 0, left: 0, right: 0,
        child: Container(
          height: 120,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: Container(
          height: 180,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter, end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
        ),
      ),

      // Header
      Positioned(
        top: 0, left: 0, right: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              // Botão fechar
              GestureDetector(
                onTap: _transmitindo ? null : () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              if (_transmitindo) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🔴 AO VIVO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Text('$_chunksEnviados segmentos',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
              const Spacer(),
              // Trocar câmara (sempre disponível quando há 2+ câmaras)
              if (_cameras.length > 1)
                GestureDetector(
                  onTap: _trocandoCamera ? null : _trocarCamera,
                  child: _trocandoCamera
                      ? const SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.flip_camera_android_rounded, color: Colors.white, size: 28),
                ),
            ]),
          ),
        ),
      ),

      // Campo título (antes de transmitir)
      if (!_transmitindo)
        Positioned(
          bottom: 140, left: 24, right: 24,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Título da transmissão...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
              onChanged: (v) => _titulo = v.isEmpty ? 'Transmissão ao Vivo' : v,
            ),
          ),
        ),

      // Botões principais
      Positioned(
        bottom: 48, left: 0, right: 0,
        child: Center(
          child: _parando
              ? const CircularProgressIndicator(color: Colors.white)
              : _transmitindo
                  ? GestureDetector(
                      onTap: _pararTransmissao,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.redAccent,
                        ),
                        child: const Icon(Icons.stop_rounded, color: Colors.white, size: 36),
                      ),
                    )
                  : GestureDetector(
                      onTap: _iniciarTransmissao,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.redAccent,
                        ),
                        child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 36),
                      ),
                    ),
        ),
      ),

      // Dica (antes de transmitir)
      if (!_transmitindo)
        const Positioned(
          bottom: 24, left: 0, right: 0,
          child: Center(
            child: Text('Toca no botão para iniciar a transmissão',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        ),
    ]);
  }

  Future<void> _trocarCamera() async {
    if (_camCtrl == null || _cameras.length < 2 || _trocandoCamera) return;
    setState(() => _trocandoCamera = true);

    final currentDir = _camCtrl!.description.lensDirection;

    // Parar gravação activa se a houver
    bool estaGravando = _camCtrl!.value.isRecordingVideo;
    if (estaGravando) {
      try { await _camCtrl!.stopVideoRecording(); } catch (_) {}
    }
    _chunkTimer?.cancel();

    await _camCtrl!.dispose();

    // Seleccionar câmara com direcção oposta
    final next = _cameras.firstWhere(
      (c) => c.lensDirection != currentDir,
      orElse: () => _cameras.firstWhere((c) => c.lensDirection == currentDir),
    );

    final ctrl = CameraController(next, ResolutionPreset.medium, enableAudio: true);
    await ctrl.initialize();
    if (!mounted) { ctrl.dispose(); return; }
    setState(() { _camCtrl = ctrl; _trocandoCamera = false; });

    // Retomar gravação se estava a transmitir
    if (_transmitindo) {
      final token = context.read<AuthProvider>().token;
      await _gravarEEnviarChunk(token);
      _chunkTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
        if (_transmitindo) await _gravarEEnviarChunk(token);
      });
    }
  }
}
