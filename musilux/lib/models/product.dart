class ProductMedia {
  final String id;
  final String urlArchivo;
  final bool esPrincipal;
  final String tipoMultimedia;

  ProductMedia({
    required this.id,
    required this.urlArchivo,
    required this.esPrincipal,
    required this.tipoMultimedia,
  });

  factory ProductMedia.fromJson(Map<String, dynamic> json) {
    return ProductMedia(
      id: json['id']?.toString() ?? '',
      urlArchivo: json['url_archivo']?.toString() ?? '',
      esPrincipal: json['es_principal'] == true || json['es_principal'] == 1,
      tipoMultimedia: json['tipo_multimedia']?.toString() ?? 'imagen',
    );
  }
}

class ProductCategory {
  final String id;
  final String nombre;
  final String slug;

  ProductCategory({required this.id, required this.nombre, required this.slug});

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }
}

class ProductTag {
  final String id;
  final String nombre;

  ProductTag({required this.id, required this.nombre});

  factory ProductTag.fromJson(Map<String, dynamic> json) {
    return ProductTag(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
    );
  }
}

class Product {
  final String id;
  final String nombre;
  final double precio;
  final String slug;
  final int inventario;
  final bool estaActivo;
  final String? descripcion;
  final String tipoProducto;
  final String? idCategoria;
  final int? bpm;
  final List<ProductMedia> multimedia;
  final ProductCategory? categoria;
  final List<ProductTag> etiquetas;
  final String? youtubeVideoId;
  final String? youtubeTitle;
  final String? youtubeChannel;
  final String? youtubeThumbnail;

  Product({
    required this.id,
    required this.nombre,
    required this.precio,
    this.slug = '',
    this.inventario = 0,
    this.estaActivo = false,
    this.descripcion,
    this.tipoProducto = 'fisico',
    this.idCategoria,
    this.bpm,
    this.multimedia = const [],
    this.categoria,
    this.etiquetas = const [],
    this.youtubeVideoId,
    this.youtubeTitle,
    this.youtubeChannel,
    this.youtubeThumbnail,
  });

  // Retorna la URL de la imagen principal o un placeholder si no hay multimedia.
  String get imageUrl {
    if (multimedia.isEmpty) {
      return 'https://placehold.co/300x300/png?text=Sin+Imagen';
    }
    final mainMedia = multimedia.firstWhere(
      (m) => m.esPrincipal && m.tipoMultimedia == 'imagen',
      orElse: () => multimedia.firstWhere(
        (m) => m.tipoMultimedia == 'imagen',
        orElse: () => multimedia.first,
      ),
    );
    return mainMedia.urlArchivo;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '0',
      nombre: json['nombre']?.toString() ?? 'Sin título',
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      slug: (json['slug'] ?? '').toString(),
      inventario: (json['inventario'] as num?)?.toInt() ?? 0,
      estaActivo: json['esta_activo'] == true || json['esta_activo'] == 1,
      descripcion: json['descripcion']?.toString(),
      tipoProducto: json['tipo_producto']?.toString() ?? 'fisico',
      idCategoria: json['id_categoria']?.toString(),
      bpm: json['bpm'] != null ? int.tryParse(json['bpm'].toString()) : null,
      multimedia: json['multimedia'] != null
          ? (json['multimedia'] as List)
              .map((i) => ProductMedia.fromJson(i))
              .toList()
          : [],
      // FIX: la API devuelve la clave 'categoria', no 'category'
      categoria: json['categoria'] != null
          ? ProductCategory.fromJson(json['categoria'])
          : null,
      etiquetas: json['etiquetas'] != null
          ? (json['etiquetas'] as List)
              .map((i) => ProductTag.fromJson(i))
              .toList()
          : [],
      youtubeVideoId: json['youtube_video_id']?.toString(),
      youtubeTitle: json['youtube_title']?.toString(),
      youtubeChannel: json['youtube_channel']?.toString(),
      youtubeThumbnail: json['youtube_thumbnail']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_categoria': idCategoria,
      'nombre': nombre,
      'precio': precio,
      'descripcion': descripcion,
      'inventario': inventario,
      'tipo_producto': tipoProducto,
      'bpm': bpm,
      'esta_activo': estaActivo,
      'youtube_video_id': youtubeVideoId,
      'youtube_title': youtubeTitle,
      'youtube_channel': youtubeChannel,
      'youtube_thumbnail': youtubeThumbnail,
    };
  }
}
