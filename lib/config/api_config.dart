class ApiConfig {
  // Backend usa HTTPS + mTLS na porta 3000
  // Emulador Android → 10.0.2.2 aponta para o localhost do PC
  static const String baseUrl = 'https://10.0.2.2:3000';

  static const String apiUrl = '$baseUrl/api';

  static String streamUrl(String videoId) => '$apiUrl/stream/$videoId';
  static String hlsUrl(String hlsPath) => '$baseUrl/$hlsPath';
  static String thumbnailUrl(String thumbPath) => '$baseUrl/$thumbPath';
  static String uploadsUrl(String path) => '$baseUrl/$path';
}