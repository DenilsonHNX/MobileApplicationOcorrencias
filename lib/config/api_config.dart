class ApiConfig {
  // Emulador Android → 10.0.2.2 aponta para o localhost do PC
  // Telemóvel físico via cabo → adb reverse tcp:3000 tcp:3000 e usar localhost:3000
  static const String baseUrl = 'http://10.0.2.2:3000';
  static const String apiUrl = '$baseUrl/api';

  static String streamUrl(String videoId) => '$apiUrl/stream/$videoId';
  static String hlsUrl(String hlsPath) => '$baseUrl/$hlsPath';
  static String thumbnailUrl(String thumbPath) => '$baseUrl/$thumbPath';
  static String uploadsUrl(String path) => '$baseUrl/$path';
}
