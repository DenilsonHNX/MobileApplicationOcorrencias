import '../config/api_config.dart';

class VideoModel {
  final String id;
  final String titulo;
  final String descricao;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? hlsUrl;
  final String userId;
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
    required this.videoUrl,
    this.thumbnailUrl,
    this.hlsUrl,
    required this.userId,
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
    return VideoModel(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      hlsUrl: json['hlsUrl'],
      userId: json['userId'] ?? '',
      nomeAutor: json['nomeAutor'] ??
          (json['autor'] is Map ? json['autor']['nome'] : null) ??
          'Utilizador',
      categoriaId: json['categoriaId'],
      categoriaNome: json['categoriaNome'] ??
          (json['categoria'] is Map ? json['categoria']['nome'] : null),
      localizacao: json['localizacao'] is Map
          ? Map<String, dynamic>.from(json['localizacao'] as Map)
          : null,
      duracao: (json['duracao'] ?? 0).toDouble(),
      visualizacoes: json['visualizacoes'] ?? 0,
      likes: json['likes'] ?? 0,
      comentarios: json['comentarios'] ?? 0,
      estado: json['estado'] ?? 'ativo',
      dataCriacao: json['dataCriacao'] != null
          ? DateTime.tryParse(json['dataCriacao'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isLiked: json['isLiked'] ?? false,
    );
  }

  String get fullStreamUrl {
    if (hlsUrl != null && hlsUrl!.isNotEmpty) {
      return ApiConfig.hlsUrl(hlsUrl!);
    }
    return ApiConfig.streamUrl(id);
  }

  String? get fullThumbnailUrl {
    if (thumbnailUrl == null || thumbnailUrl!.isEmpty) return null;
    return ApiConfig.thumbnailUrl(thumbnailUrl!);
  }

  VideoModel copyWith({bool? isLiked, int? likes, int? comentarios, int? visualizacoes}) {
    return VideoModel(
      id: id,
      titulo: titulo,
      descricao: descricao,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      hlsUrl: hlsUrl,
      userId: userId,
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
