import '../config/api_config.dart';

class VideoModel {
  final String id;
  final String titulo;
  final String descricao;
  final String? thumbnail;      // caminho relativo, ex: "uploads/thumbnails/xxx.jpg"
  final String? streamUrlFull;  // URL completo do endpoint de detalhe
  final String? hlsUrlFull;     // URL completo HLS do endpoint de detalhe
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
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    final autor = json['autor'];
    final nomeAutor = (autor is Map ? autor['nome'] : null) ?? 'Utilizador';

    return VideoModel(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      thumbnail: json['thumbnail'],
      // streamUrl e hlsUrl só existem na resposta de detalhe (/api/videos/:id)
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
      // Backend usa 'views', não 'visualizacoes'
      visualizacoes: json['views'] ?? json['visualizacoes'] ?? 0,
      likes: json['likes'] ?? 0,
      comentarios: json['comentarios'] ?? 0,
      estado: json['estado'] ?? 'ativo',
      // Backend usa 'criadoEm', não 'dataCriacao'
      dataCriacao: (json['criadoEm'] ?? json['dataCriacao']) != null
          ? DateTime.tryParse((json['criadoEm'] ?? json['dataCriacao']).toString()) ?? DateTime.now()
          : DateTime.now(),
      // Backend usa 'likedPorMim', não 'isLiked'
      isLiked: json['likedPorMim'] ?? json['isLiked'] ?? false,
    );
  }

  String get fullStreamUrl {
    // HLS tem melhor qualidade de streaming — usar se disponível
    if (hlsUrlFull != null && hlsUrlFull!.isNotEmpty) return hlsUrlFull!;
    // Stream direto via endpoint
    if (streamUrlFull != null && streamUrlFull!.isNotEmpty) return streamUrlFull!;
    // Fallback: construir a partir do ID
    return ApiConfig.streamUrl(id);
  }

  String? get fullThumbnailUrl {
    if (thumbnail == null || thumbnail!.isEmpty) return null;
    if (thumbnail!.startsWith('http')) return thumbnail;
    return '${ApiConfig.baseUrl}/$thumbnail';
  }

  VideoModel copyWith({bool? isLiked, int? likes, int? comentarios, int? visualizacoes}) {
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
    );
  }
}
