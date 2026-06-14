import 'package:flutter/material.dart';
import '../services/video_service.dart';

class ReportDialog extends StatefulWidget {
  final String videoId;
  final String token;

  const ReportDialog({super.key, required this.videoId, required this.token});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  static const _motivos = [
    'Conteúdo não autorizado',
    'Violação de direitos de autor',
    'Informação falsa',
    'Conteúdo ofensivo',
    'Conteúdo impróprio',
  ];

  String? _motivoSelecionado;
  bool _loading = false;

  Future<void> _enviar() async {
    if (_motivoSelecionado == null) return;
    setState(() => _loading = true);
    try {
      await VideoService.denunciar(widget.videoId, _motivoSelecionado!, widget.token);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Denúncia enviada. A nossa equipa irá analisá-la.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Row(
        children: [
          Icon(Icons.flag_rounded, color: Colors.redAccent),
          SizedBox(width: 8),
          Text('Denunciar Vídeo', style: TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Selecione o motivo da denúncia:',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          RadioGroup<String>(
            groupValue: _motivoSelecionado,
            onChanged: (v) => setState(() => _motivoSelecionado = v),
            child: Column(
              children: _motivos
                  .map((m) => RadioListTile<String>(
                        value: m,
                        title: Text(m, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        activeColor: Colors.redAccent,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: (_loading || _motivoSelecionado == null) ? null : _enviar,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enviar'),
        ),
      ],
    );
  }
}
