import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/video_model.dart';
import '../models/comment_model.dart';
import 'http_client.dart';

class VideoService {
  static Future<List<VideoModel>> getFeed({
    int pagina = 1,
    int limite = 10,
    String? categoriaId,
    String? pesquisa,
    String? token,
  }) async {
    final params = {
      'pagina': '$pagina',
      'limite': '$limite',
      'categoriaId': ?categoriaId,
      if (pesquisa != null && pesquisa.isNotEmpty) 'pesquisa': pesquisa,
    };
    final uri = Uri.parse('${ApiConfig.apiUrl}/videos').replace(queryParameters: params);
    final headers = token != null ? {'Authorization': 'Bearer $token'} : <String, String>{};
    final client = await SecureClient.instance;
    final response = await client.get(uri, headers: headers);
    if (response.statusCode != 200) throw Exception('Erro ao carregar vídeos');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final lista = data['videos'] ?? data['data'] ?? [];
    return (lista as List).map((v) => VideoModel.fromJson(v as Map<String, dynamic>)).toList();
  }

  static Future<VideoModel> getVideo(String id, {String? token}) async {
    final headers = token != null ? {'Authorization': 'Bearer $token'} : <String, String>{};
    final client = await SecureClient.instance;
    final response = await client.get(
      Uri.parse('${ApiConfig.apiUrl}/videos/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) throw Exception('Vídeo não encontrado');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return VideoModel.fromJson(data['video'] ?? data);
  }

  static Future<bool> toggleLike(String videoId, String token) async {
    final client = await SecureClient.instance;
    final response = await client.post(
      Uri.parse('${ApiConfig.apiUrl}/videos/$videoId/like'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Erro ao reagir ao vídeo');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['gostou'] ?? false;
  }

  static Future<List<CommentModel>> getComentarios(String videoId) async {
    final client = await SecureClient.instance;
    final response = await client.get(
      Uri.parse('${ApiConfig.apiUrl}/videos/$videoId/comentarios'),
    );
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final lista = data['comentarios'] ?? data['data'] ?? [];
    return (lista as List).map((c) => CommentModel.fromJson(c as Map<String, dynamic>)).toList();
  }

  static Future<CommentModel> addComentario(String videoId, String texto, String token) async {
    final client = await SecureClient.instance;
    final response = await client.post(
      Uri.parse('${ApiConfig.apiUrl}/videos/$videoId/comentarios'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'texto': texto}),
    );
    if (response.statusCode != 201) throw Exception('Erro ao adicionar comentário');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CommentModel.fromJson(data['comentario'] ?? data);
  }

  static Future<void> denunciar(String videoId, String motivo, String token) async {
    final client = await SecureClient.instance;
    final response = await client.post(
      Uri.parse('${ApiConfig.apiUrl}/videos/$videoId/denunciar'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'motivo': motivo}),
    );
    if (response.statusCode != 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['erro'] ?? 'Erro ao denunciar');
    }
  }

  static Future<VideoModel> uploadVideo({
    required File videoFile,
    required String titulo,
    required String descricao,
    required String categoriaId,
    required String token,
    double? latitude,
    double? longitude,
    bool termos = true,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.apiUrl}/videos/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['titulo'] = titulo;
    request.fields['descricao'] = descricao;
    request.fields['categoriaId'] = categoriaId;
    request.fields['termos'] = termos.toString();
    if (latitude != null) request.fields['latitude'] = latitude.toString();
    if (longitude != null) request.fields['longitude'] = longitude.toString();

    request.files.add(await http.MultipartFile.fromPath('video', videoFile.path));

    final client = await SecureClient.instance;
    final streamed = await client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['erro'] ?? 'Erro ao publicar vídeo');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return VideoModel.fromJson(data['video'] ?? data);
  }
}
