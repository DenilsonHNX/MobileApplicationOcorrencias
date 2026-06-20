import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import '../config/api_config.dart';
import '../models/video_model.dart';
import '../models/comment_model.dart';
import 'mtls_client.dart';

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
      if (pesquisa != null && pesquisa.isNotEmpty) 'q': pesquisa,
    };
    final uri = Uri.parse('${ApiConfig.apiUrl}/videos').replace(queryParameters: params);
    final headers = token != null ? {'Authorization': 'Bearer $token'} : <String, String>{};
    final client = await MtlsClient.get();
    final response = await client.get(uri, headers: headers);
    if (response.statusCode != 200) throw Exception('Erro ao carregar vídeos');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final lista = data['videos'] ?? [];
    return (lista as List).map((v) => VideoModel.fromJson(v as Map<String, dynamic>)).toList();
  }

  static Future<VideoModel> getVideo(String id, {String? token}) async {
    final headers = token != null ? {'Authorization': 'Bearer $token'} : <String, String>{};
    final client = await MtlsClient.get();
    final response = await client.get(
      Uri.parse('${ApiConfig.apiUrl}/videos/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) throw Exception('Vídeo não encontrado');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return VideoModel.fromJson(data);
  }

  static Future<bool> toggleLike(String videoId, String token) async {
    final client = await MtlsClient.get();
    final response = await client.post(
      Uri.parse('${ApiConfig.apiUrl}/videos/$videoId/like'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Erro ao reagir ao vídeo');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['liked'] ?? false;
  }

  static Future<List<CommentModel>> getComentarios(String videoId) async {
    final client = await MtlsClient.get();
    final response = await client.get(
      Uri.parse('${ApiConfig.apiUrl}/videos/$videoId/comentarios'),
    );
    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body);
    final lista = body is List ? body : (body['comentarios'] ?? body['data'] ?? []);
    return (lista as List).map((c) => CommentModel.fromJson(c as Map<String, dynamic>)).toList();
  }

  static Future<CommentModel> addComentario(String videoId, String texto, String token) async {
    final client = await MtlsClient.get();
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
    return CommentModel.fromJson(data);
  }

  static Future<void> denunciar(String videoId, String motivo, String token) async {
    final client = await MtlsClient.get();
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
      throw Exception(data['error'] ?? 'Erro ao denunciar');
    }
  }

  static Future<bool> toggleGuardar(String videoId, String token) async {
    final client = await MtlsClient.get();
    final response = await client.post(
      Uri.parse('${ApiConfig.apiUrl}/videos/$videoId/guardar'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Erro ao guardar vídeo');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['guardado'] ?? false;
  }

  static Future<List<VideoModel>> getGuardados(String token) async {
    final client = await MtlsClient.get();
    final response = await client.get(
      Uri.parse('${ApiConfig.apiUrl}/videos/guardados'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body);
    final lista = body is List ? body : (body['videos'] ?? []);
    return (lista as List).map((v) => VideoModel.fromJson(v as Map<String, dynamic>)).toList();
  }

  static Future<List<VideoModel>> getMeusVideos(String token) async {
    final client = await MtlsClient.get();
    final response = await client.get(
      Uri.parse('${ApiConfig.apiUrl}/videos/meus'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body);
    final lista = body is List ? body : (body['videos'] ?? []);
    return (lista as List).map((v) => VideoModel.fromJson(v as Map<String, dynamic>)).toList();
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
    final client = await MtlsClient.get();

    final ext = p.extension(videoFile.path).toLowerCase().replaceFirst('.', '');
    final mimeMap = {
      'mp4': 'video/mp4', 'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska', 'mov': 'video/quicktime',
      'webm': 'video/webm', '3gp': 'video/3gpp', '3gpp': 'video/3gpp',
    };
    final mime = (mimeMap[ext] ?? 'video/mp4').split('/');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.apiUrl}/videos/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['titulo'] = titulo;
    request.fields['descricao'] = descricao;
    request.fields['categoriaId'] = categoriaId;
    request.fields['termoAceite'] = termos.toString();
    if (latitude != null) request.fields['latitude'] = latitude.toString();
    if (longitude != null) request.fields['longitude'] = longitude.toString();
    request.files.add(await http.MultipartFile.fromPath(
      'video', videoFile.path,
      contentType: MediaType(mime[0], mime[1]),
    ));

    final streamed = await client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Erro ao publicar vídeo');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return VideoModel.fromJson(data['video'] ?? data);
  }
}
