import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../widgets/shared_components.dart';
import '../services/youtube_service.dart';
import '../widgets/youtube_search_widget.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = _apiService.fetchProducts();
    });
  }

  // --- LÓGICA DE ELIMINAR ---
  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este producto permanentemente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _apiService.deleteProduct(id);
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Producto eliminado')));
        _refreshProducts();
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error al eliminar')));
      }
    }
  }

  // --- FORMULARIO DE CREAR / EDITAR ---
  void _showFormDialog({Product? product}) {
    YoutubeVideo? selectedTrack = (product != null && product.youtubeVideoId != null)
        ? YoutubeVideo(
            videoId: product.youtubeVideoId!,
            title: product.youtubeTitle ?? '',
            channel: product.youtubeChannel ?? '',
            thumbnail: product.youtubeThumbnail,
          )
        : null;
    final isEditing = product != null;
    final formKey = GlobalKey<FormState>();

    // Controladores
    final nameCtrl = TextEditingController(text: product?.nombre ?? '');
    final priceCtrl = TextEditingController(
      text: product?.precio.toString() ?? '',
    );
    final stockCtrl = TextEditingController(
      text: product?.inventario.toString() ?? '0',
    );
    final imgCtrl = TextEditingController(text: product?.imageUrl ?? '');
    final descCtrl = TextEditingController(text: product?.descripcion ?? '');
    final bpmCtrl = TextEditingController(text: product?.bpm?.toString() ?? '');
    String typeValue = product?.tipoProducto ?? 'fisico';

    // Aseguramos que el valor inicial sea válido (1, 2 o 3)
    String categoryValue = product?.idCategoria ?? '1';
    if (!['1', '2', '3'].contains(categoryValue)) {
      categoryValue = '1';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
        content: SizedBox(
          width: 400, // Ancho fijo para web/desktop
          child: StatefulBuilder(
            builder: (context, setInnerState) {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Producto',
                        ),
                        validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: priceCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Precio',
                                prefixText: '\$ ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: stockCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Inventario',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: categoryValue,
                              decoration: const InputDecoration(
                                labelText: 'Categoría',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: '1',
                                  child: Text('Instrumentos'),
                                ),
                                DropdownMenuItem(
                                  value: '2',
                                  child: Text('Iluminación'),
                                ),
                                DropdownMenuItem(
                                  value: '3',
                                  child: Text('Vinilos'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setInnerState(() => categoryValue = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: bpmCtrl,
                              decoration: const InputDecoration(
                                labelText: 'BPM (Opcional)',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: typeValue,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: const [
                          DropdownMenuItem(
                            value: 'fisico',
                            child: Text('Físico'),
                          ),
                          DropdownMenuItem(
                            value: 'digital',
                            child: Text('Digital'),
                          ),
                          DropdownMenuItem(
                            value: 'servicio',
                            child: Text('Servicio'),
                          ),
                        ],
                        onChanged: (val) => typeValue = val!,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: imgCtrl,
                        decoration: const InputDecoration(
                          labelText: 'URL Imagen (Opcional)',
                          helperText: 'Deja vacío para usar imagen por defecto',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 10),
                      if (categoryValue == '3')
                        YoutubeSearchWidget(
                          initialVideo: selectedTrack,
                          onVideoSelected: (v) {
                            selectedTrack = v;
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final navigator = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);
                final newProduct = Product(
                  id:
                      product?.id ??
                      '0', // Si es nuevo, el ID se ignora en el POST
                  nombre: nameCtrl.text,
                  precio: double.tryParse(priceCtrl.text) ?? 0.0,
                  inventario: int.tryParse(stockCtrl.text) ?? 0,
                  descripcion: descCtrl.text,
                  tipoProducto: typeValue,
                  estaActivo: true, // Activo por defecto
                  idCategoria: categoryValue,
                  bpm: int.tryParse(bpmCtrl.text),
                  youtubeVideoId: selectedTrack?.videoId,
                  youtubeTitle: selectedTrack?.title,
                  youtubeChannel: selectedTrack?.channel,
                  youtubeThumbnail: selectedTrack?.thumbnail,
                  // Nota: la subida de imágenes requiere un multipart request al backend, por el momento se omitió en el modelo directo.
                );

                bool success;
                if (isEditing) {
                  success = await _apiService.updateProduct(
                    product.id,
                    newProduct,
                  );
                } else {
                  success = await _apiService.createProduct(newProduct);
                }

                if (mounted) {
                  navigator.pop();
                  if (success) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing
                              ? 'Actualizado correctamente'
                              : 'Creado correctamente',
                        ),
                      ),
                    );
                    _refreshProducts();
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Error al guardar en base de datos'),
                      ),
                    );
                  }
                }
              }
            },
            child: Text(
              isEditing ? 'Guardar Cambios' : 'Crear',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Administración de Productos',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Nuevo Producto',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No hay productos en la base de datos.'),
                  );
                }

                final products = snapshot.data!;

                // Usamos un LayoutBuilder para hacer la tabla responsive
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Imagen')),
                            DataColumn(label: Text('Nombre')),
                            DataColumn(label: Text('Tipo')),
                            DataColumn(label: Text('Precio')),
                            DataColumn(label: Text('Stock')),
                            DataColumn(label: Text('Acciones')),
                          ],
                          rows: products.map((product) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.grey[200],
                                    ),
                                    child: product.imageUrl.isNotEmpty
                                        ? Image.network(
                                            product.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                const Icon(
                                                  Icons.broken_image,
                                                  size: 20,
                                                ),
                                          )
                                        : const Icon(
                                            Icons.image,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    product.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                DataCell(Text(product.tipoProducto)),
                                DataCell(Text('\$${product.precio}')),
                                DataCell(Text(product.inventario.toString())),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () =>
                                            _showFormDialog(product: product),
                                        tooltip: 'Editar',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _deleteProduct(product.id),
                                        tooltip: 'Eliminar',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
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
}
