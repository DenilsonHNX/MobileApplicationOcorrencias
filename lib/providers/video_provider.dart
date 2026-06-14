import 'package:flutter/material.dart';
import '../models/video_model.dart';
import '../models/category_model.dart';
import '../services/video_service.dart';
import '../services/category_service.dart';

class VideoProvider extends ChangeNotifier {
  List<VideoModel> _videos = [];
  List<CategoryModel> _categorias = [];
  bool _loading = false;
  bool _hasMore = true;
  int _pagina = 1;
  String? _categoriaFiltro;
  String? _pesquisa;

  List<VideoModel> get videos => _videos;
  List<CategoryModel> get categorias => _categorias;
  bool get loading => _loading;
  bool get hasMore => _hasMore;
  String? get categoriaFiltro => _categoriaFiltro;

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
    } catch (_) {
      _hasMore = false;
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
