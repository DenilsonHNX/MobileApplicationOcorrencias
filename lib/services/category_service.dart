import 'dart:convert';
import '../config/api_config.dart';
import '../models/category_model.dart';
import 'mtls_client.dart';

class CategoryService {
  static Future<List<CategoryModel>> getCategorias() async {
    final client = await MtlsClient.get();
    final response = await client.get(Uri.parse('${ApiConfig.apiUrl}/categorias'));
    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body);
    final lista = body is List ? body : (body['categorias'] ?? body['data'] ?? []);
    return (lista as List)
        .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}
