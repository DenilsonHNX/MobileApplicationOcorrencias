class ApiConfig {
  static const String baseUrl        = 'https://192.168.137.1:3000';
  static const String mediaBaseUrl   = 'http://192.168.137.1:3001';
  static const String tcpBroadcastHost = '192.168.137.1';
  static const int    tcpBroadcastPort = 9999;
  static const String apiUrl      = '$baseUrl/api';

  // Stream e HLS via HTTP (porta 3001) — player nativo não suporta mTLS
  static String streamUrl(String videoId) => '$mediaBaseUrl/api/stream/$videoId';
  static String hlsUrl(String hlsPath)    => '$mediaBaseUrl/$hlsPath';
  static String thumbnailUrl(String path) => '$mediaBaseUrl/$path';
  static String uploadsUrl(String path)   => '$mediaBaseUrl/$path';
}