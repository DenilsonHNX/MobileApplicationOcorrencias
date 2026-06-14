import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/category_model.dart';

class CategoryService {
  static Future<List<CategoryModel>> getCategorias() async {
    final response = await http.get(Uri.parse('${ApiConfig.apiUrl}/categorias'));
    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body);
    // Backend devolve array direto: [...], não { categorias: [...] }
    final lista = body is List ? body : (body['categorias'] ?? body['data'] ?? []);
    return (lista as List)
        .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}
