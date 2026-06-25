import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../models/category_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/video_provider.dart';
import '../../services/video_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _picker = ImagePicker();

  File? _videoFile;
  VideoPlayerController? _previewCtrl;
  CategoryModel? _categoria;
  bool _termos = false;
  bool _loading = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _previewCtrl?.dispose();
    super.dispose();
  }

  Future<bool> _checkPermission(ImageSource source) async {
    final Permission perm =
        source == ImageSource.camera ? Permission.camera : Permission.videos;
    final status = await perm.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      _showSnack('Permissão negada permanentemente. Active nas definições.');
      await openAppSettings();
    } else {
      _showSnack(source == ImageSource.camera
          ? 'Permissão de câmara necessária.'
          : 'Permissão de armazenamento necessária.');
    }
    return false;
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (!await _checkPermission(source)) return;

    final picked = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 15),
    );
    if (picked == null) return;
    await _setVideoFile(File(picked.path));
  }

  Future<void> _pickVideoFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    await _setVideoFile(File(path));
  }

  Future<void> _setVideoFile(File file) async {
    await _previewCtrl?.dispose();
    final ctrl = VideoPlayerController.file(file);
    await ctrl.initialize();
    setState(() {
      _videoFile = file;
      _previewCtrl = ctrl;
    });
  }

  Future<void> _publicar() async {
    if (_videoFile == null) return;
    if (_tituloCtrl.text.trim().isEmpty) {
      _showSnack('Introduza um título para o vídeo.');
      return;
    }
    if (_categoria == null) {
      _showSnack('Selecione uma categoria.');
      return;
    }
    if (!_termos) {
      _showSnack('Deve aceitar os termos de responsabilidade.');
      return;
    }

    setState(() => _loading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      await VideoService.uploadVideo(
        videoFile: _videoFile!,
        titulo: _tituloCtrl.text.trim(),
        descricao: _descCtrl.text.trim(),
        categoriaId: _categoria!.id,
        token: token,
        termos: true,
      );
      if (mounted) {
        context.read<VideoProvider>().loadFeed(token: token, refresh: true);
        _showSnack('Vídeo publicado com sucesso!', success: true);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.videocam_rounded, color: Colors.blueAccent),
              title: const Text('Gravar com câmara', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _pickVideo(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.blueAccent),
              title: const Text('Escolher da galeria', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _pickVideo(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_rounded, color: Colors.blueAccent),
              title: const Text('Escolher de ficheiros', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Downloads, Drive, SD Card...', style: TextStyle(color: Colors.white38, fontSize: 12)),
              onTap: () { Navigator.pop(context); _pickVideoFromFiles(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categorias = context.watch<VideoProvider>().categorias;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Publicar Ocorrência', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 16),
                  Text('A publicar e processar vídeo...', style: TextStyle(color: Colors.white54)),
                  Text('(compressão automática em curso)', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Área de selecção de vídeo
                  GestureDetector(
                    onTap: _showSourcePicker,
                    child: Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: _previewCtrl != null && _previewCtrl!.value.isInitialized
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _previewCtrl!.value.size.width,
                                  height: _previewCtrl!.value.size.height,
                                  child: VideoPlayer(_previewCtrl!),
                                ),
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline_rounded, size: 56, color: Colors.blueAccent),
                                SizedBox(height: 12),
                                Text('Toque para selecionar um vídeo', style: TextStyle(color: Colors.white54)),
                                Text('Câmara ou galeria • máx. 15 minutos', style: TextStyle(color: Colors.white38, fontSize: 12)),
                              ],
                            ),
                    ),
                  ),

                  if (_videoFile != null) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: _showSourcePicker,
                        icon: const Icon(Icons.swap_horiz_rounded, color: Colors.blueAccent),
                        label: const Text('Trocar vídeo', style: TextStyle(color: Colors.blueAccent)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const _SectionLabel('Informações'),
                  const SizedBox(height: 12),

                  // Título
                  _buildTextField(_tituloCtrl, 'Título da ocorrência *', Icons.title_rounded, maxLines: 1),
                  const SizedBox(height: 12),
                  // Descrição
                  _buildTextField(_descCtrl, 'Descrição (opcional)', Icons.description_outlined, maxLines: 3),
                  const SizedBox(height: 12),

                  // Categoria
                  DropdownButtonFormField<CategoryModel>(
                    initialValue: _categoria,
                    dropdownColor: const Color(0xFF1A1A2E),
                    decoration: _inputDecoration('Categoria *', Icons.category_outlined),
                    items: categorias
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.label, style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _categoria = v),
                    hint: const Text('Selecione uma categoria', style: TextStyle(color: Colors.white38)),
                  ),

                  const SizedBox(height: 24),
                  const _SectionLabel('Termo de Responsabilidade'),
                  const SizedBox(height: 8),

                  // Termos
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'Ao publicar este conteúdo, declaro que:\n\n'
                      '• Este vídeo é da minha autoria ou possuo autorização legal para a sua divulgação;\n'
                      '• Não estou a partilhar conteúdo de terceiros sem permissão;\n'
                      '• Assumo total responsabilidade pelo conteúdo publicado;\n'
                      '• Estou ciente que conteúdos falsos ou não autorizados podem resultar na suspensão da conta.',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _termos,
                    onChanged: (v) => setState(() => _termos = v ?? false),
                    activeColor: Colors.blueAccent,
                    checkColor: Colors.white,
                    title: const Text(
                      'Confirmo que este vídeo é da minha autoria ou possuo autorização legal para a sua divulgação e assumo total responsabilidade pelo conteúdo publicado.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (_videoFile != null && _termos) ? _publicar : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        disabledBackgroundColor: Colors.white24,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.publish_rounded),
                      label: const Text('Publicar Ocorrência', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(hint, icon),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: Colors.white38),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
