class CategoryModel {
  final String id;
  final String nome;
  final String? emoji;
  final String? descricao;

  const CategoryModel({
    required this.id,
    required this.nome,
    this.emoji,
    this.descricao,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      emoji: json['emoji'],
      descricao: json['descricao'],
    );
  }

  String get label => emoji != null ? '$emoji $nome' : nome;
}
