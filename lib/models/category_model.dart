class CategoryModel {
  final String id;
  final String nome;
  final String? icone; // backend usa 'icone', não 'emoji'

  const CategoryModel({
    required this.id,
    required this.nome,
    this.icone,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      icone: json['icone'] ?? json['emoji'],
    );
  }

  String get label => icone != null ? '$icone $nome' : nome;
}
