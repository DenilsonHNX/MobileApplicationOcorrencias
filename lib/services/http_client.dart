import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/io_client.dart';

// Cliente HTTP singleton com mTLS:
//  - Confia APENAS na CA-ISPTEC (não nas CAs do sistema)
//  - Envia o certificado do app como certificado de cliente
class SecureClient {
  static IOClient? _instance;

  static Future<IOClient> get instance async {
    _instance ??= await _build();
    return _instance!;
  }

  static Future<IOClient> _build() async {
    final caBytes   = await rootBundle.load('assets/certs/ca.crt');
    final certBytes = await rootBundle.load('assets/certs/app.crt');
    final keyBytes  = await rootBundle.load('assets/certs/app.key');

    final sc = SecurityContext(withTrustedRoots: false);
    sc.setTrustedCertificatesBytes(caBytes.buffer.asUint8List());
    sc.useCertificateChainBytes(certBytes.buffer.asUint8List());
    sc.usePrivateKeyBytes(keyBytes.buffer.asUint8List());

    final httpClient = HttpClient(context: sc);
    return IOClient(httpClient);
  }

  // Limpa o singleton (útil em testes ou reload de certs)
  static void reset() => _instance = null;
}
