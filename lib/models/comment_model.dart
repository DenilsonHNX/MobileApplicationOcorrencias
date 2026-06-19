class CommentModel {
  final String id;
  final String videoId;
  final String userId;
  final String nomeAutor;
  final String texto;
  final DateTime dataCriacao;

  const CommentModel({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.nomeAutor,
    required this.texto,
    required this.dataCriacao,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      videoId: json['videoId'] ?? '',
      userId: json['userId'] ?? '',
      nomeAutor: json['nomeAutor'] ??
          (json['autor'] is Map ? json['autor']['nome'] : null) ??
          'Utilizador',
      texto: json['texto'] ?? '',
      dataCriacao: json['dataCriacao'] != null
          ? DateTime.tryParse(json['dataCriacao'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
