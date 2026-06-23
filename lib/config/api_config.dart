class ApiConfig {
  static const String baseUrl     = 'https://172.16.20.9:3000';
  static const String mediaBaseUrl = 'http://172.16.20.9:3001';
  static const String apiUrl      = '$baseUrl/api';

  // Stream e HLS via HTTP (porta 3001) — player nativo não suporta mTLS
  static String streamUrl(String videoId) => '$mediaBaseUrl/api/stream/$videoId';
  static String hlsUrl(String hlsPath)    => '$mediaBaseUrl/$hlsPath';
  static String thumbnailUrl(String path) => '$mediaBaseUrl/$path';
  static String uploadsUrl(String path)   => '$mediaBaseUrl/$path';
}