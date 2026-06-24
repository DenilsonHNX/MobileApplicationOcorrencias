import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';

// ─────────────────────────── VIEWER ──────────────────────────────────────────

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  bool _aoVivo      = false;
  String? _titulo;
  String? _iniciadoEm;
  bool _verificando = true;

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
    super.dispose();
  }

  Future<void> _verificarStatus() async {
    try {
      final uri = Uri.parse('${ApiConfig.mediaBaseUrl}/api/live/status');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _aoVivo      = data['ao_vivo'] == true;
        _titulo      = data['titulo'] as String?;
        _iniciadoEm  = data['iniciadoEm'] as String?;
        _verificando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _verificando = false);
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastScreen()))
        .then((_) => _verificarStatus());
  }

  void _abrirViewer() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TcpViewerScreen()));
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
          : _aoVivo ? _buildAoVivo() : _buildOffline(auth),
    );
  }

  Widget _buildAoVivo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
            child: const Text('🔴 AO VIVO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 20),
          Text(
            _titulo ?? 'Transmissão ao Vivo',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (_iniciadoEm != null) ...[
            const SizedBox(height: 8),
            Text('Desde ${_fmtHora(_iniciadoEm)}',
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ],
          const SizedBox(height: 40),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: const Text('Assistir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: _abrirViewer,
          ),
          const SizedBox(height: 12),
          const Text('Stream em tempo real via TCP', style: TextStyle(color: Colors.white24, fontSize: 11)),
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

// ─────────────────────────── TCP VIEWER ──────────────────────────────────────

class TcpViewerScreen extends StatefulWidget {
  const TcpViewerScreen({super.key});

  @override
  State<TcpViewerScreen> createState() => _TcpViewerScreenState();
}

class _TcpViewerScreenState extends State<TcpViewerScreen> {
  Socket?    _socket;
  Uint8List? _frame;
  String?    _erro;
  bool       _conectando = true;
  int        _fps        = 0;
  int        _frameCount = 0;
  Timer?     _fpsTimer;

  // Buffer para montar frames do protocolo TCP
  final List<int> _buf = [];

  @override
  void initState() {
    super.initState();
    _connect();
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() { _fps = _frameCount; _frameCount = 0; });
    });
  }

  @override
  void dispose() {
    _fpsTimer?.cancel();
    _socket?.destroy();
    super.dispose();
  }

  Future<void> _connect() async {
    try {
      final socket = await Socket.connect(
        ApiConfig.tcpBroadcastHost,
        ApiConfig.tcpBroadcastPort,
        timeout: const Duration(seconds: 8),
      );
      _socket = socket;

      // Enviar role VIEWER (16 bytes com padding)
      final role = 'VIEWER'.padRight(16);
      socket.add(Uint8List.fromList(utf8.encode(role)));

      if (mounted) setState(() => _conectando = false);

      socket.listen(
        (data) {
          _buf.addAll(data);
          _processBuffer();
        },
        onError: (_) { if (mounted) setState(() => _erro = 'Conexão perdida.'); },
        onDone:  ()  { if (mounted) setState(() => _erro = 'Transmissão encerrada.'); },
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) setState(() { _conectando = false; _erro = e.toString(); });
    }
  }

  void _processBuffer() {
    while (_buf.length >= 4) {
      final size = (_buf[0] << 24) | (_buf[1] << 16) | (_buf[2] << 8) | _buf[3];
      if (_buf.length < 4 + size) break;
      final jpeg = Uint8List.fromList(_buf.sublist(4, 4 + size));
      _buf.removeRange(0, 4 + size);
      _frameCount++;
      if (mounted) setState(() => _frame = jpeg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
            child: const Text('🔴 AO VIVO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Text('$_fps fps', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white54),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _conectando
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(color: Colors.redAccent),
              SizedBox(height: 16),
              Text('A ligar ao stream...', style: TextStyle(color: Colors.white54)),
            ]))
          : _erro != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.signal_wifi_bad_rounded, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(_erro!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: () { setState(() { _erro = null; _conectando = true; _buf.clear(); }); _connect(); },
                    child: const Text('Tentar novamente')),
                ]))
              : _frame == null
                  ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      CircularProgressIndicator(color: Colors.white24),
                      SizedBox(height: 12),
                      Text('À espera do primeiro frame...', style: TextStyle(color: Colors.white38)),
                    ]))
                  : SizedBox.expand(
                      child: Image.memory(_frame!,
                        gaplessPlayback: true,
                        fit: BoxFit.contain,
                      ),
                    ),
    );
  }
}

// ─────────────────────────── TCP BROADCASTER ─────────────────────────────────

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  CameraController? _camCtrl;
  List<CameraDescription> _cameras = [];
  bool _iniciando      = true;
  bool _transmitindo   = false;
  bool _parando        = false;
  bool _trocandoCamera = false;
  String? _erro;
  int _framesSent = 0;
  int _fps        = 0;
  int _fpsCount   = 0;
  Socket? _socket;
  Timer?  _frameTimer;
  Timer?  _fpsTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() { _fps = _fpsCount; _fpsCount = 0; });
    });
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _fpsTimer?.cancel();
    _socket?.destroy();
    _camCtrl?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception('Nenhuma câmara encontrada.');
      final idx = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      final cam = _cameras[idx >= 0 ? idx : 0];
      final ctrl = CameraController(cam, ResolutionPreset.medium, enableAudio: false);
      await ctrl.initialize();
      if (!mounted) return;
      setState(() { _camCtrl = ctrl; _iniciando = false; });
    } catch (e) {
      if (mounted) setState(() { _erro = e.toString(); _iniciando = false; });
    }
  }

  Future<void> _iniciarTransmissao() async {
    if (_camCtrl == null || _transmitindo) return;
    try {
      // Ligar ao servidor TCP como STREAMER
      final socket = await Socket.connect(
        ApiConfig.tcpBroadcastHost,
        ApiConfig.tcpBroadcastPort,
        timeout: const Duration(seconds: 8),
      );
      _socket = socket;
      socket.add(Uint8List.fromList(utf8.encode('STREAMER'.padRight(16))));
      socket.listen((_) {}, onError: (_) => _pararTransmissao(), onDone: () => _pararTransmissao());

      setState(() { _transmitindo = true; _framesSent = 0; });

      // Capturar e enviar um frame a cada ~100ms (≈10fps)
      _frameTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
        if (!_transmitindo || _camCtrl == null) return;
        try {
          final file = await _camCtrl!.takePicture();
          final bytes = await File(file.path).readAsBytes();
          File(file.path).deleteSync();

          // Protocolo: 4 bytes big-endian + JPEG
          final sz = bytes.length;
          final header = Uint8List(4)
            ..[0] = (sz >> 24) & 0xff
            ..[1] = (sz >> 16) & 0xff
            ..[2] = (sz >> 8)  & 0xff
            ..[3] =  sz        & 0xff;
          _socket?.add(header);
          _socket?.add(bytes);
          _fpsCount++;
          if (mounted) setState(() => _framesSent++);
        } catch (_) {}
      });
    } catch (e) {
      if (mounted) setState(() => _erro = 'Erro ao ligar: $e');
    }
  }

  Future<void> _pararTransmissao() async {
    if (!_transmitindo && _socket == null) return;
    setState(() { _parando = true; });
    _frameTimer?.cancel();
    _frameTimer = null;
    _socket?.destroy();
    _socket = null;
    if (mounted) setState(() { _transmitindo = false; _parando = false; });
  }

  Future<void> _trocarCamera() async {
    if (_camCtrl == null || _cameras.length < 2 || _trocandoCamera) return;
    setState(() => _trocandoCamera = true);

    final wasTransmitting = _transmitindo;
    if (wasTransmitting) {
      _frameTimer?.cancel();
      _frameTimer = null;
    }

    final currentDir = _camCtrl!.description.lensDirection;
    await _camCtrl!.dispose();

    final next = _cameras.firstWhere(
      (c) => c.lensDirection != currentDir,
      orElse: () => _cameras.first,
    );

    final ctrl = CameraController(next, ResolutionPreset.medium, enableAudio: false);
    await ctrl.initialize();
    if (!mounted) { ctrl.dispose(); return; }
    setState(() { _camCtrl = ctrl; _trocandoCamera = false; });

    if (wasTransmitting) {
      _frameTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
        if (!_transmitindo || _camCtrl == null) return;
        try {
          final file = await _camCtrl!.takePicture();
          final bytes = await File(file.path).readAsBytes();
          File(file.path).deleteSync();
          final sz = bytes.length;
          final header = Uint8List(4)
            ..[0] = (sz >> 24) & 0xff
            ..[1] = (sz >> 16) & 0xff
            ..[2] = (sz >> 8)  & 0xff
            ..[3] =  sz        & 0xff;
          _socket?.add(header);
          _socket?.add(bytes);
          _fpsCount++;
          if (mounted) setState(() => _framesSent++);
        } catch (_) {}
      });
    }
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
          Text(_erro!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Voltar')),
        ]),
      ),
    );
  }

  Widget _buildBroadcaster() {
    return Stack(fit: StackFit.expand, children: [
      if (_camCtrl != null) CameraPreview(_camCtrl!),

      // Gradiente topo
      Positioned(top: 0, left: 0, right: 0,
        child: Container(height: 120,
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.transparent])))),

      // Gradiente base
      Positioned(bottom: 0, left: 0, right: 0,
        child: Container(height: 180,
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent])))),

      // Header
      Positioned(top: 0, left: 0, right: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              GestureDetector(
                onTap: _transmitindo ? null : () => Navigator.pop(context),
                child: Icon(Icons.close_rounded, color: _transmitindo ? Colors.white24 : Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              if (_transmitindo) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
                  child: const Text('🔴 AO VIVO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Text('$_fps fps  •  $_framesSent frames',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
              const Spacer(),
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
        )),

      // Campo título
      if (!_transmitindo)
        Positioned(bottom: 140, left: 24, right: 24,
          child: Container(
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Título da transmissão...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
          )),

      // Botão principal
      Positioned(bottom: 48, left: 0, right: 0,
        child: Center(
          child: _parando
              ? const CircularProgressIndicator(color: Colors.white)
              : GestureDetector(
                  onTap: _transmitindo ? _pararTransmissao : _iniciarTransmissao,
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _transmitindo ? Colors.white : Colors.redAccent,
                    ),
                    child: Icon(
                      _transmitindo ? Icons.stop_rounded : Icons.videocam_rounded,
                      color: _transmitindo ? Colors.redAccent : Colors.white,
                      size: 36,
                    ),
                  ),
                ),
        )),

      if (!_transmitindo)
        const Positioned(bottom: 24, left: 0, right: 0,
          child: Center(
            child: Text('Toca no botão para transmitir via TCP',
              style: TextStyle(color: Colors.white38, fontSize: 12)))),
    ]);
  }
}
