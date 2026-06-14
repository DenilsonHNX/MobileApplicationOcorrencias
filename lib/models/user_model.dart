class UserModel {
  final String id;
  final String nome;
  final String email;
  final String role;
  final String estado;
  final DateTime dataCriacao;

  const UserModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.role,
    required this.estado,
    required this.dataCriacao,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      estado: json['estado'] ?? 'ativo',
      // Backend usa 'criadoEm', não 'dataCriacao'
      dataCriacao: (json['criadoEm'] ?? json['dataCriacao']) != null
          ? DateTime.tryParse((json['criadoEm'] ?? json['dataCriacao']).toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isActive => estado == 'ativo';
}
