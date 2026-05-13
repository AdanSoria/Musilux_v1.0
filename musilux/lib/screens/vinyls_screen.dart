import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../widgets/shared_components.dart';
import '../providers/cart_provider.dart';
import '../theme/colors.dart';

class VinylsScreen extends StatefulWidget {
  const VinylsScreen({super.key});

  @override
  State<VinylsScreen> createState() => _VinylsScreenState();
}

class _VinylsScreenState extends State<VinylsScreen> {
  String _selectedCategory = 'Todos';
  String _selectedSort = 'Recomendados';

  late Future<List<Product>> _productsFuture;
  final ApiService _apiService = ApiService();

  final List<String> _categories = [
    'Todos',
    'Rock',
    'Pop',
    'Jazz',
    'Clásica',
    'Electrónica',
    'Grunge',
    'Metal',
    'Acustico',
    'Alternativo',
  ];
  final List<String> _sortOptions = [
    'Recomendados',
    'Precio: Menor a Mayor',
    'Precio: Mayor a Menor',
  ];

  @override
  void initState() {
    super.initState();
    _productsFuture = _apiService.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    int crossAxisCount = 4;
    if (screenWidth < 600) {
      crossAxisCount = 1;
    } else if (screenWidth < 900) {
      crossAxisCount = 2;
    } else if (screenWidth < 1200) {
      crossAxisCount = 3;
    }

    return BaseLayout(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40,
          vertical: 30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Discos de Vinilo',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'La mejor calidad de audio analógico de tus artistas favoritos.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),

            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterChips(),
                  const SizedBox(height: 16),
                  _buildSortDropdown(),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildFilterChips()),
                  const SizedBox(width: 20),
                  _buildSortDropdown(),
                ],
              ),

            const SizedBox(height: 30),

            FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No hay discos disponibles.'),
                  );
                }

                // Filtrar solo Vinilos (idCategoria == '3')
                var products = snapshot.data!
                    .where((p) => p.idCategoria == '3')
                    .toList();

                // Filtro por género (busca en nombre del producto)
                if (_selectedCategory != 'Todos') {
                  products = products
                      .where(
                        (p) => p.nombre.toLowerCase().contains(
                          _selectedCategory.toLowerCase(),
                        ),
                      )
                      .toList();
                }

                // Ordenamiento
                if (_selectedSort == 'Precio: Menor a Mayor') {
                  products.sort((a, b) => a.precio.compareTo(b.precio));
                } else if (_selectedSort == 'Precio: Mayor a Menor') {
                  products.sort((a, b) => b.precio.compareTo(a.precio));
                }

                if (products.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.album_outlined,
                            size: 56,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedCategory == 'Todos'
                                ? 'No hay discos disponibles.'
                                : 'No hay discos de "$_selectedCategory".',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final item = products[index];
                    return ProductCard(
                      title: item.nombre,
                      price: item.precio,
                      tags: item.categoria != null
                          ? [item.categoria!.nombre]
                          : [],
                      imageUrl: item.imageUrl,
                      isSale: item.estaActivo,
                      onDetailsTap: () => Navigator.pushNamed(
                        context,
                        '/detalle-producto/${item.id}',
                      ),
                      onAdd: () {
                        context.read<CartProvider>().agregarProducto(
                          productoId: item.id,
                          nombre: item.nombre,
                          precio: item.precio,
                          imagenUrl: item.imageUrl,
                          stockDisponible: item.inventario,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Agregado al carrito')),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((category) {
        final isSelected = _selectedCategory == category;
        return ChoiceChip(
          label: Text(
            category,
            style: TextStyle(color: isSelected ? Colors.white : Colors.black87),
          ),
          selected: isSelected,
          selectedColor: AppColors.primaryPurple,
          backgroundColor: Colors.grey.shade200,
          onSelected: (selected) {
            setState(() {
              _selectedCategory = category;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sort, size: 20, color: Colors.black54),
          const SizedBox(width: 8),
          const Text('Ordenar por: ', style: TextStyle(color: Colors.black54)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSort,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primaryPurple,
              ),
              items: _sortOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedSort = newValue;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
