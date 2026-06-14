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
      // Backend usa 'autorNome', não 'nomeAutor'
      nomeAutor: json['autorNome'] ?? json['nomeAutor'] ?? 'Utilizador',
      texto: json['texto'] ?? '',
      // Backend usa 'criadoEm', não 'dataCriacao'
      dataCriacao: (json['criadoEm'] ?? json['dataCriacao']) != null
          ? DateTime.tryParse((json['criadoEm'] ?? json['dataCriacao']).toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
