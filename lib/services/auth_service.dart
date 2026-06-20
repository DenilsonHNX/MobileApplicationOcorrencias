import 'dart:convert';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'mtls_client.dart';

class AuthService {
  static Future<Map<String, dynamic>> registar({
    required String nome,
    required String email,
    required String password,
  }) async {
    final client = await MtlsClient.get();
    final response = await client.post(
      Uri.parse('${ApiConfig.apiUrl}/auth/registar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nome': nome, 'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw Exception(data['error'] ?? 'Erro ao criar conta');
    }
    return data;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final client = await MtlsClient.get();
    final response = await client.post(
      Uri.parse('${ApiConfig.apiUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Credenciais inválidas');
    }
    return data;
  }

  static Future<UserModel> getPerfil(String token) async {
    final client = await MtlsClient.get();
    final response = await client.get(
      Uri.parse('${ApiConfig.apiUrl}/auth/perfil'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Sessão expirada');
    }
    return UserModel.fromJson(data);
  }
}
