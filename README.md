# OcorrênciasApp — Aplicação Mobile (Flutter/Android)

Cliente Android para a plataforma de partilha de ocorrências em vídeo. Autenticação mTLS, reprodução via ExoPlayer e download de vídeos.

---

## Requisitos

- [Flutter SDK](https://flutter.dev/) 3.x ou superior
- Android Studio ou VS Code com extensão Flutter
- Dispositivo Android 8.0+ (API 26) ou emulador
- Servidor Backend activo na mesma rede

---

## Instalação

```bash
git clone https://github.com/DenilsonHNX/MobileApplicationOcorrencias.git
cd MobileApplicationOcorrencias
flutter pub get
```

---

## Configuração

### Endereço do Servidor

Editar [lib/config/api_config.dart](lib/config/api_config.dart):

```dart
static const String baseUrl     = 'https://192.168.X.X:3000';
static const String streamBaseUrl = 'http://192.168.X.X:3001';
```

Substituir `192.168.X.X` pelo IP do servidor na rede local.

### Certificados mTLS

Os certificados estão em `assets/certs/` (`ca.crt`, `app.crt`, `app.key`). São usados automaticamente. Para actualizar, substituir pelos ficheiros gerados pela PKI do servidor.

---

## Executar

```bash
# Debug (dispositivo ligado por USB ou emulador activo)
flutter run

# APK de release
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Estrutura

```
lib/
├── config/       # Endereços da API
├── models/       # VideoModel, UserModel, etc.
├── providers/    # AuthProvider, VideoProvider
├── screens/
│   ├── auth/     # Login e registo
│   ├── home/     # Feed principal
│   ├── search/   # Pesquisa
│   ├── upload/   # Publicar vídeo
│   ├── profile/  # Perfil do utilizador
│   └── video/    # Detalhe e player completo
├── services/     # Chamadas à API
├── widgets/      # VideoPlayerItem, CommentsSheet, etc.
└── main.dart

assets/
└── certs/        # ca.crt, app.crt, app.key (mTLS)
```

---

## Funcionalidades

- Autenticação JWT com ligação mTLS ao servidor
- Feed vertical com scroll (estilo TikTok) e barra de progresso arrastável
- Player completo: Play/Pause, Stop, ±10s, Volume, Seek
- Download para `/storage/emulated/0/Download/`
- Upload da galeria ou câmara com compressão automática no servidor
- Pesquisa por título/descrição com miniatura
- Like, comentários, guardar, partilhar, denunciar
- Perfil com vídeos criados e guardados

---

## Dependências Principais

| Pacote | Uso |
|---|---|
| `video_player` | Reprodução (ExoPlayer) |
| `image_picker` | Galeria / câmara |
| `http` | API e download |
| `provider` | Gestão de estado |
| `shared_preferences` | Token JWT local |
| `share_plus` | Partilha |
| `permission_handler` | Permissões Android |
