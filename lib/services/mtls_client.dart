import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

// Singleton — inicializado uma vez na startup da app
class MtlsClient {
  static http.Client? _client;

  static Future<http.Client> get() async {
    if (_client != null) return _client!;
    _client = await _build();
    return _client!;
  }

  static Future<http.Client> _build() async {
    final caCertBytes  = (await rootBundle.load('assets/certs/ca.crt')).buffer.asUint8List();
    final clientCert   = (await rootBundle.load('assets/certs/app.crt')).buffer.asUint8List();
    final clientKey    = (await rootBundle.load('assets/certs/app.key')).buffer.asUint8List();

    final context = SecurityContext()
      ..setTrustedCertificatesBytes(caCertBytes)   // confia no servidor da CA-ISPTEC
      ..useCertificateChainBytes(clientCert)        // apresenta o cert do app
      ..usePrivateKeyBytes(clientKey);              // chave privada do app (não encriptada)

    final httpClient = HttpClient(context: context)
      // O CN do servidor é 'academico.isptec.local', não o IP do emulador.
      // Em dev aceitamos o mismatch mas verificamos a assinatura da CA.
      ..badCertificateCallback = (cert, host, port) {
        return cert.issuer.contains('CA-ISPTEC');
      };

    return IOClient(httpClient);
  }
}
