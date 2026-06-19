class ApiConfig {
  // HTTPS + mTLS — o certificado do servidor tem SAN: localhost
  // Via cabo USB com adb reverse tcp:3000 tcp:3000 → localhost funciona direto
  // Emulador Android → usar 10.0.2.2 se adb reverse não estiver ativo
  static const String baseUrl = 'https://localhost:3000';
  static const String apiUrl = '$baseUrl/api';

  static String streamUrl(String videoId) => '$apiUrl/stream/$videoId';
  static String hlsUrl(String hlsPath) => '$baseUrl/$hlsPath';
  static String thumbnailUrl(String thumbPath) => '$baseUrl/$thumbPath';
  static String uploadsUrl(String path) => '$baseUrl/$path';
}
