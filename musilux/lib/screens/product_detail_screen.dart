import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:musilux/models/product.dart';
import 'package:musilux/services/api_service.dart';
import '../providers/cart_provider.dart';
import '../theme/colors.dart';
import '../widgets/shared_components.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class ProductDetailScreen extends StatefulWidget {
  final String? productId;
  const ProductDetailScreen({super.key, this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late Future<Product> _productFuture;
  final ApiService _apiService = ApiService();
  String? _productId;

  late PageController _pageController;
  int _currentImageIndex = 0;
  bool _expandDescription = false;

  // Skeleton pulse animation
  late AnimationController _skeletonCtrl;
  late Animation<double> _skeletonAnim;

  bool get _isMobile => MediaQuery.of(context).size.width < 800;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _skeletonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _skeletonAnim = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _skeletonCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _skeletonCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final extractedId = widget.productId ?? args?.toString();
    if (extractedId != null && extractedId != _productId) {
      setState(() {
        _productId = extractedId;
        _currentImageIndex = 0;
        _expandDescription = false;
        _productFuture = _apiService.fetchProductById(_productId!);
      });
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    } else if (_productId == null) {
      setState(() {
        _productFuture = Future.error('No se proporcionó un ID de producto.');
      });
    }
  }

  void _agregarAlCarrito(
    BuildContext context,
    Product product, {
    bool abrirCarrito = false,
  }) {
    final cart = context.read<CartProvider>();
    final resultado = cart.agregarProducto(
      productoId: product.id,
      nombre: product.nombre,
      precio: product.precio,
      imagenUrl: product.imageUrl,
      stockDisponible: product.inventario,
    );

    String mensaje;
    Color color;

    switch (resultado) {
      case CartAddResult.exito:
        mensaje = '${product.nombre} agregado al carrito';
        color = AppColors.success;
        if (abrirCarrito) Scaffold.of(context).openEndDrawer();
        break;
      case CartAddResult.sinStock:
        mensaje = 'Sin stock disponible';
        color = AppColors.error;
      case CartAddResult.limiteNegocio:
        mensaje = 'Máximo 10 unidades por producto';
        color = AppColors.warning;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hPad = _isMobile ? 20.0 : 48.0;
    return BaseLayout(
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 48),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: EdgeInsets.all(_isMobile ? 20 : 40),
          child: FutureBuilder<Product>(
            future: _productFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildSkeleton();
              }
              if (snapshot.hasError) {
                return _buildError(snapshot.error.toString());
              }
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: Text('Producto no encontrado.')),
                );
              }
              final product = snapshot.data!;
              return _isMobile
                  ? _buildMobileLayout(product)
                  : _buildDesktopLayout(product);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Error: $error',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ── Skeleton Loader ────────────────────────────────────────────

  Widget _buildSkeleton() {
    return AnimatedBuilder(
      animation: _skeletonAnim,
      builder: (_, _) {
        final opacity = _skeletonAnim.value;

        Widget box({double w = double.infinity, double h = 20, double r = 6}) =>
            Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300.withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(r),
              ),
            );

        final imageBlock = box(h: 300, r: 12);
        final thumbnailRow = Row(
          children: List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: box(w: 64, h: 64, r: 8),
            ),
          ),
        );
        final infoBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            box(w: 80, h: 24, r: 12),
            const SizedBox(height: 12),
            box(h: 28),
            const SizedBox(height: 8),
            box(w: 200, h: 28),
            const SizedBox(height: 12),
            box(w: 130, h: 34, r: 4),
            const SizedBox(height: 16),
            box(w: 170, h: 18),
            const SizedBox(height: 16),
            box(h: 14),
            const SizedBox(height: 6),
            box(h: 14),
            const SizedBox(height: 6),
            box(w: 240, h: 14),
            const SizedBox(height: 32),
            box(h: 50, r: 10),
          ],
        );

        if (_isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              imageBlock,
              const SizedBox(height: 12),
              thumbnailRow,
              const SizedBox(height: 24),
              infoBlock,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  imageBlock,
                  const SizedBox(height: 12),
                  thumbnailRow,
                ],
              ),
            ),
            const SizedBox(width: 40),
            Expanded(flex: 5, child: infoBlock),
          ],
        );
      },
    );
  }

  // ── Layouts ────────────────────────────────────────────────────

  Widget _buildMobileLayout(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageColumn(product),
        const SizedBox(height: 24),
        _buildInfoColumn(product),
        if (_productId != null) _buildRelatedProducts(_productId!),
      ],
    );
  }

  Widget _buildDesktopLayout(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _buildImageColumn(product)),
            const SizedBox(width: 40),
            Expanded(flex: 5, child: _buildInfoColumn(product)),
          ],
        ),
        if (_productId != null) _buildRelatedProducts(_productId!),
      ],
    );
  }

  // ── Galería con carousel y swipe ───────────────────────────────

  Widget _buildImageColumn(Product product) {
    final imageMedia = product.multimedia
        .where((m) => m.tipoMultimedia == 'imagen')
        .toList();
    final urls = imageMedia.isNotEmpty
        ? imageMedia.map((m) => m.urlArchivo).toList()
        : <String>[product.imageUrl];

    return Column(
      children: [
        Semantics(
          label: 'Galería de imágenes de ${product.nombre}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: _isMobile ? 300.0 : 520.0,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentImageIndex = i),
                itemCount: urls.length,
                itemBuilder: (_, i) => CachedNetworkImage(
                  imageUrl: urls[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  filterQuality: FilterQuality.high,
                  memCacheHeight: _isMobile ? 900 : 1560,
                  placeholder: (_, _) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Tira de miniaturas — visible solo si hay más de 1 imagen
        if (urls.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Semantics(
                label: 'Imagen ${i + 1} de ${urls.length}',
                button: true,
                child: GestureDetector(
                  onTap: () => _pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                  ),
                  child: _ThumbnailTile(
                    url: urls[i],
                    isActive: _currentImageIndex == i,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Columna de información ─────────────────────────────────────

  Widget _buildInfoColumn(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip de categoría
        if (product.categoria != null)
          Semantics(
            label: 'Categoría: ${product.categoria!.nombre}',
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                product.categoria!.nombre.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),

        // Nombre
        Text(
          product.nombre,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Precio
        Text(
          '\$${product.precio.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryPurple,
          ),
        ),
        const SizedBox(height: 16),

        // Stock y BPM
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  product.inventario > 0
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  size: 18,
                  color: product.inventario > 0
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(width: 6),
                Text(
                  product.inventario > 0
                      ? 'Stock: ${product.inventario} disponibles'
                      : 'Agotado',
                  style: TextStyle(
                    fontSize: 14,
                    color: product.inventario > 0
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (product.bpm != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.speed,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${product.bpm} BPM',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Etiquetas (tags)
        if (product.etiquetas.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: product.etiquetas
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tagBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tag.nombre,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.tagText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],

        const SizedBox(height: 16),

        // Descripción colapsable
        if (product.descripcion != null && product.descripcion!.isNotEmpty) ...[
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Text(
              product.descripcion!,
              maxLines: _expandDescription ? null : 3,
              overflow: _expandDescription
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.7,
              ),
            ),
          ),
          GestureDetector(
            onTap: () =>
                setState(() => _expandDescription = !_expandDescription),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _expandDescription ? 'Ver menos' : 'Ver más',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    _expandDescription
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.primaryPurple,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Player de YouTube si hay video asociado
        if (product.youtubeVideoId != null)
          _YoutubeAudioPlayer(product: product)
        else if (product.tipoProducto == 'digital')
          _buildAudioDemo(),
        if (product.tipoProducto == 'servicio') _buildLightingDemo(),

        const SizedBox(height: 32),

        // Botones de compra
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: product.inventario > 0
                    ? () => _agregarAlCarrito(context, product)
                    : null,
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text(
                  'Agregar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: product.inventario > 0
                    ? () => _agregarAlCarrito(
                        context,
                        product,
                        abrirCarrito: true,
                      )
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryPurple,
                  side: const BorderSide(color: AppColors.primaryPurple),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Comprar Ahora',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Demos ──────────────────────────────────────────────────────

  Widget _buildAudioDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Demo de Audio',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.skip_previous, size: 30),
            SizedBox(width: 20),
            Icon(Icons.play_arrow, size: 40, color: AppColors.primaryPurple),
            SizedBox(width: 20),
            Icon(Icons.skip_next, size: 30),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('00:00', style: TextStyle(fontSize: 12)),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const Text('01:30', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildLightingDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Simulador de Colores DMX',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _ColorCircle(Colors.red),
            const SizedBox(width: 10),
            _ColorCircle(Colors.green),
            const SizedBox(width: 10),
            _ColorCircle(Colors.blue),
            const SizedBox(width: 10),
            _ColorCircle(Colors.purple),
            const SizedBox(width: 10),
            _ColorCircle(Colors.yellow),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Selecciona un color para ver una vista previa.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  // ── Productos Relacionados ─────────────────────────────────────

  Widget _buildRelatedProducts(String productId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 56),
        const Text(
          'También te puede interesar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Product>>(
          future: _apiService.fetchRelatedProducts(productId),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, _) => Container(
                    width: 140,
                    height: 210,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            }
            if (!snap.hasData || snap.data!.isEmpty) {
              return const SizedBox.shrink();
            }
            final related = snap.data!;
            return SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: related.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _RelatedProductCard(
                  product: related[i],
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProductDetailScreen(productId: related[i].id),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── YouTube Player ─────────────────────────────────────────────

class _YoutubeAudioPlayer extends StatefulWidget {
  final Product product;
  const _YoutubeAudioPlayer({required this.product});

  @override
  State<_YoutubeAudioPlayer> createState() => _YoutubeAudioPlayerState();
}

class _YoutubeAudioPlayerState extends State<_YoutubeAudioPlayer> {
  YoutubePlayerController? _controller;
  bool _playerVisible = false;

  static const _ytRed = Color(0xFFFF0000);

  @override
  void initState() {
    super.initState();
    final videoId = widget.product.youtubeVideoId;
    if (videoId != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: _ytRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, size: 12, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text(
              'Video de la canción',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: _playerVisible && _controller != null
              ? YoutubePlayerScaffold(
                  controller: _controller!,
                  builder: (context, player) => player,
                )
              : _buildThumbnail(p, isMobile),
        ),
      ],
    );
  }

  Widget _buildThumbnail(Product p, bool isMobile) {
    final h = isMobile ? 200.0 : 260.0;
    return GestureDetector(
      onTap: () {
        setState(() => _playerVisible = true);
        _controller?.playVideo();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (p.youtubeThumbnail != null)
            CachedNetworkImage(
              imageUrl: p.youtubeThumbnail!,
              width: double.infinity,
              height: h,
              fit: BoxFit.cover,
              placeholder: (ctx, url) => Container(height: h, color: const Color(0xFF282828)),
              errorWidget: (ctx, url, err) => Container(
                height: h,
                color: const Color(0xFF282828),
                child: const Icon(Icons.play_circle_outline, color: Colors.white54, size: 48),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: h,
              color: const Color(0xFF282828),
              child: const Icon(Icons.play_circle_outline, color: Colors.white54, size: 48),
            ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _ytRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _ytRed.withValues(alpha: 0.5),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 32, 12, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xDD000000), Colors.transparent],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (p.youtubeTitle != null)
                    Text(
                      p.youtubeTitle!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  if (p.youtubeChannel != null)
                    Text(
                      p.youtubeChannel!,
                      style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets internos ───────────────────────────────────────────

class _ThumbnailTile extends StatelessWidget {
  final String url;
  final bool isActive;
  const _ThumbnailTile({required this.url, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? AppColors.primaryPurple : Colors.grey.shade200,
          width: isActive ? 2.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.5),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          memCacheWidth: 192,
          memCacheHeight: 192,
          placeholder: (_, _) => Container(color: AppColors.surfaceVariant),
          errorWidget: (_, _, _) => Container(
            color: AppColors.surfaceVariant,
            child: const Icon(
              Icons.image_not_supported_outlined,
              size: 24,
              color: AppColors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

class _RelatedProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _RelatedProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                height: 110,
                width: 140,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                memCacheWidth: 420,
                memCacheHeight: 330,
                placeholder: (_, _) =>
                    Container(height: 110, color: AppColors.surfaceVariant),
                errorWidget: (_, _, _) => Container(
                  height: 110,
                  color: AppColors.surfaceVariant,
                  child: const Icon(
                    Icons.music_note,
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;
  const _ColorCircle(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}
