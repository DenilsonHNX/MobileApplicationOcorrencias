import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'mtls_client.dart';

class LiveService {
  static Future<void> uploadChunk(String filePath, {String? token, String? titulo}) async {
    final client = await MtlsClient.get();
    final uri = Uri.parse('${ApiConfig.apiUrl}/live/chunk');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (titulo != null) request.fields['titulo'] = titulo;
    request.files.add(await http.MultipartFile.fromPath('chunk', filePath));
    final streamed = await client.send(request).timeout(const Duration(seconds: 20));
    await streamed.stream.drain();
  }

  static Future<void> stopCameraLive({String? token}) async {
    final client = await MtlsClient.get();
    final uri = Uri.parse('${ApiConfig.apiUrl}/live/stop-camera');
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    await client.post(uri, headers: headers).timeout(const Duration(seconds: 10));
  }
}
