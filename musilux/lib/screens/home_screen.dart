import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:musilux/models/product.dart';
import 'package:musilux/services/api_service.dart';
import '../widgets/shared_components.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> _productsFuture;
  final ApiService _apiService = ApiService();

  bool get isMobile => MediaQuery.of(context).size.width < 800;
  EdgeInsets get _hPad => EdgeInsets.symmetric(horizontal: isMobile ? 20 : 48);

  @override
  void initState() {
    super.initState();
    _productsFuture = _apiService.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(),
          const SizedBox(height: 56),
          _buildSectionHeader('Explora Nuestras Categorías', null),
          const SizedBox(height: 20),
          _buildCategories(),
          const SizedBox(height: 56),
          _buildSectionHeader('Ofertas Especiales', '/instrumentos'),
          const SizedBox(height: 4),
          Padding(
            padding: _hPad,
            child: const Text(
              'Productos seleccionados con los mejores precios.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 20),
          _buildSaleProducts(),
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  // ── Hero Banner ──────────────────────────────────────────────
  Widget _buildHero() {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: isMobile ? 260 : 420,
          child: CachedNetworkImage(
            imageUrl:
                'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=1200&q=80',
            fit: BoxFit.cover,
            placeholder: (ctx, url) => Container(color: AppColors.headerBg),
            errorWidget: (ctx, url, err) =>
                Container(color: AppColors.headerBg),
          ),
        ),
        Container(
          width: double.infinity,
          height: isMobile ? 260 : 420,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xCC1E1B2E), Color(0x881E1B2E)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: _hPad,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.primaryPurple.withValues(alpha: 0.6),
                    ),
                  ),
                  child: const Text(
                    'NUEVA COLECCIÓN 2026',
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Tu Música,\nTu Estilo.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 32 : 48,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Instrumentos, iluminación y vinilos de calidad.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isMobile ? 14 : 17,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/instrumentos'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Comprar Ahora',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/contacto'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Contáctanos',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Encabezado de sección con enlace opcional ────────────────
  Widget _buildSectionHeader(String title, String? route) {
    return Padding(
      padding: _hPad,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (route != null)
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, route),
              icon: const Text(
                'Ver todos',
                style: TextStyle(color: AppColors.primaryPurple, fontSize: 13),
              ),
              label: const Icon(
                Icons.arrow_forward,
                size: 16,
                color: AppColors.primaryPurple,
              ),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
        ],
      ),
    );
  }

  // ── Categorías ───────────────────────────────────────────────
  Widget _buildCategories() {
    final categories = [
      {
        'title': 'Instrumentos',
        'subtitle': 'Guitarras, Bajos, Baterías',
        'image':
            'https://ortizo.com.co/cdn/shop/articles/INSTRUMENTOS.jpg?v=1736287757&width=1920',
        'route': '/instrumentos',
      },
      {
        'title': 'Iluminación',
        'subtitle': 'Soluciones para cada ambiente',
        'image':
            'https://images.unsplash.com/photo-1533923156502-be31530547c4?w=600&q=80',
        'route': '/iluminacion',
      },
      {
        'title': 'Vinilos',
        'subtitle': 'Tus artistas favoritos',
        'image':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSJVPVcvu-yGVS4NFvor8Dmz97wDYj3ZETMsA&s',
        'route': '/vinilos',
      },
    ];

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: _hPad,
        itemCount: categories.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          final cat = categories[i];
          return CategoryCard(
            width: isMobile ? 260 : 320,
            title: cat['title']!,
            subtitle: cat['subtitle']!,
            imageUrl: cat['image']!,
            onTap: () => Navigator.pushNamed(context, cat['route']!),
          );
        },
      ),
    );
  }

  // ── Productos en oferta ──────────────────────────────────────
  Widget _buildSaleProducts() {
    return SizedBox(
      height: 320,
      child: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 40,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No se pudieron cargar los productos',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          final products = (snapshot.data ?? [])
              .where((p) => p.estaActivo)
              .toList();
          if (products.isEmpty) {
            return const Center(child: Text('No hay ofertas disponibles.'));
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: _hPad,
            itemCount: products.length,
            separatorBuilder: (ctx, i) => const SizedBox(width: 16),
            itemBuilder: (_, i) {
              final product = products[i];
              return SizedBox(
                width: 220,
                child: ProductCard(
                  isSale: true,
                  title: product.nombre,
                  price: product.precio,
                  tags: const [],
                  imageUrl: product.imageUrl,
                  onDetailsTap: () => Navigator.pushNamed(
                    context,
                    '/detalle-producto/${product.id}',
                  ),
                  onAdd: () {
                    // Añadir al carrito desde tarjeta (cantidad 1)
                    context.read<CartProvider>().agregarProducto(
                      productoId: product.id,
                      nombre: product.nombre,
                      precio: product.precio,
                      imagenUrl: product.imageUrl,
                      stockDisponible: product.inventario,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Agregado al carrito')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
