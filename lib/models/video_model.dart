import '../config/api_config.dart';

class VideoModel {
  final String id;
  final String titulo;
  final String descricao;
  final String? thumbnail;
  final String? streamUrlFull;
  final String? hlsUrlFull;
  final String nomeAutor;
  final String? categoriaId;
  final String? categoriaNome;
  final Map<String, dynamic>? localizacao;
  final double duracao;
  final int visualizacoes;
  final int likes;
  final int comentarios;
  final String estado;
  final DateTime dataCriacao;
  bool isLiked;
  bool isGuardado;

  VideoModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    this.thumbnail,
    this.streamUrlFull,
    this.hlsUrlFull,
    required this.nomeAutor,
    this.categoriaId,
    this.categoriaNome,
    this.localizacao,
    this.duracao = 0,
    required this.visualizacoes,
    required this.likes,
    required this.comentarios,
    required this.estado,
    required this.dataCriacao,
    this.isLiked = false,
    this.isGuardado = false,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    final autor = json['autor'];
    final nomeAutor = (autor is Map ? autor['nome'] : null) ?? 'Utilizador';

    return VideoModel(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      thumbnail: json['thumbnail'],
      streamUrlFull: json['streamUrl'],
      hlsUrlFull: json['hlsUrl'],
      nomeAutor: nomeAutor,
      categoriaId: json['categoriaId'],
      categoriaNome: json['categoriaNome'] ??
          (json['categoria'] is Map ? json['categoria']['nome'] : null),
      localizacao: json['localizacao'] is Map
          ? Map<String, dynamic>.from(json['localizacao'] as Map)
          : null,
      duracao: (json['duracao'] ?? 0).toDouble(),
      visualizacoes: json['views'] ?? json['visualizacoes'] ?? 0,
      likes: json['likes'] ?? 0,
      comentarios: json['comentarios'] ?? 0,
      estado: json['estado'] ?? 'ativo',
      dataCriacao: (json['criadoEm'] ?? json['dataCriacao']) != null
          ? DateTime.tryParse((json['criadoEm'] ?? json['dataCriacao']).toString()) ?? DateTime.now()
          : DateTime.now(),
      isLiked: json['likedPorMim'] ?? json['isLiked'] ?? false,
      isGuardado: json['guardadoPorMim'] ?? json['isGuardado'] ?? false,
    );
  }

  String get fullStreamUrl {
    if (hlsUrlFull != null && hlsUrlFull!.isNotEmpty) return hlsUrlFull!;
    if (streamUrlFull != null && streamUrlFull!.isNotEmpty) return streamUrlFull!;
    return ApiConfig.streamUrl(id);
  }

  String? get fullThumbnailUrl {
    if (thumbnail == null || thumbnail!.isEmpty) return null;
    if (thumbnail!.startsWith('http')) return thumbnail;
    return '${ApiConfig.baseUrl}/$thumbnail';
  }

  VideoModel copyWith({bool? isLiked, bool? isGuardado, int? likes, int? comentarios, int? visualizacoes}) {
    return VideoModel(
      id: id,
      titulo: titulo,
      descricao: descricao,
      thumbnail: thumbnail,
      streamUrlFull: streamUrlFull,
      hlsUrlFull: hlsUrlFull,
      nomeAutor: nomeAutor,
      categoriaId: categoriaId,
      categoriaNome: categoriaNome,
      localizacao: localizacao,
      duracao: duracao,
      visualizacoes: visualizacoes ?? this.visualizacoes,
      likes: likes ?? this.likes,
      comentarios: comentarios ?? this.comentarios,
      estado: estado,
      dataCriacao: dataCriacao,
      isLiked: isLiked ?? this.isLiked,
      isGuardado: isGuardado ?? this.isGuardado,
    );
  }
}
