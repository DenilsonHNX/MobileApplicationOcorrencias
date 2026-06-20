import 'package:flutter/material.dart';
import '../models/video_model.dart';
import '../models/category_model.dart';
import '../services/video_service.dart';
import '../services/category_service.dart';
import '../services/mtls_client.dart';

class VideoProvider extends ChangeNotifier {
  List<VideoModel> _videos = [];
  List<CategoryModel> _categorias = [];
  List<VideoModel> _guardados = [];
  List<VideoModel> _meusVideos = [];
  bool _loading = false;
  bool _hasMore = true;
  int _pagina = 1;
  String? _categoriaFiltro;
  String? _pesquisa;
  String? _erroFeed;

  List<VideoModel> get videos => _videos;
  List<CategoryModel> get categorias => _categorias;
  List<VideoModel> get guardados => _guardados;
  List<VideoModel> get meusVideos => _meusVideos;
  bool get loading => _loading;
  bool get hasMore => _hasMore;
  String? get categoriaFiltro => _categoriaFiltro;
  String? get erroFeed => _erroFeed;

  Future<void> loadCategorias() async {
    if (_categorias.isNotEmpty) return;
    _categorias = await CategoryService.getCategorias();
    notifyListeners();
  }

  Future<void> loadFeed({String? token, bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _pagina = 1;
      _hasMore = true;
      _videos = [];
      _erroFeed = null;
    }
    if (!_hasMore) return;
    _loading = true;
    notifyListeners();

    try {
      final novos = await VideoService.getFeed(
        pagina: _pagina,
        limite: 10,
        categoriaId: _categoriaFiltro,
        pesquisa: _pesquisa,
        token: token,
      );
      if (novos.isEmpty) {
        _hasMore = false;
      } else {
        _videos.addAll(novos);
        _pagina++;
      }
    } catch (e, st) {
      debugPrint('FEED ERROR: $e\n$st');
      _hasMore = false;
      _erroFeed = e.toString();
      MtlsClient.reset(); // força nova conexão no próximo retry
    }

    _loading = false;
    notifyListeners();
  }

  void setCategoria(String? categoriaId, {String? token}) {
    _categoriaFiltro = categoriaId;
    loadFeed(token: token, refresh: true);
  }

  void pesquisar(String query, {String? token}) {
    _pesquisa = query.isEmpty ? null : query;
    loadFeed(token: token, refresh: true);
  }

  Future<void> loadGuardados(String token) async {
    _guardados = await VideoService.getGuardados(token);
    notifyListeners();
  }

  Future<void> loadMeusVideos(String token) async {
    _meusVideos = await VideoService.getMeusVideos(token);
    notifyListeners();
  }

  Future<bool> toggleGuardar(int index, String token) async {
    final video = _videos[index];
    final guardado = await VideoService.toggleGuardar(video.id, token);
    _videos[index] = video.copyWith(isGuardado: guardado);
    if (guardado) {
      if (!_guardados.any((v) => v.id == video.id)) {
        _guardados = [_videos[index], ..._guardados];
      }
    } else {
      _guardados.removeWhere((v) => v.id == video.id);
    }
    notifyListeners();
    return guardado;
  }

  Future<bool> toggleLike(int index, String token) async {
    final video = _videos[index];
    final liked = await VideoService.toggleLike(video.id, token);
    _videos[index] = video.copyWith(
      isLiked: liked,
      likes: liked ? video.likes + 1 : video.likes - 1,
    );
    notifyListeners();
    return liked;
  }

  void incrementarVisualizacoes(int index) {
    final v = _videos[index];
    _videos[index] = v.copyWith(visualizacoes: v.visualizacoes + 1);
    notifyListeners();
  }

  void incrementarComentarios(int index) {
    final v = _videos[index];
    _videos[index] = v.copyWith(comentarios: v.comentarios + 1);
    notifyListeners();
  }
}
