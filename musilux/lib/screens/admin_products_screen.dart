import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../features/catalog/data/product_model.dart';
import '../features/catalog/data/api_service.dart';
import '../services/youtube_service.dart';
import '../widgets/youtube_search_widget.dart';
import '../services/firebase_storage_service.dart';
import '../core/app_router.dart';
import '../theme/colors.dart';
import '../widgets/shared_components.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final ProductService _productService = ProductService();
  late Future<List<ProductModel>> _productsFuture;

  @override
  void initState() {
    super.initState();
    // initState: asignación directa sin setState (el widget no está montado aún)
    _productsFuture = _productService.getProducts();
  }

  void _refreshProducts() {
    setState(() => _productsFuture = _productService.getProducts());
  }

  void _showProductForm({ProductModel? product}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ProductFormDialog(
        product: product,
        onSave: (newProduct) async {
          final bool success = product == null
              ? await _productService.createProduct(newProduct)
              : await _productService.updateProduct(newProduct);

          if (!ctx.mounted) return;
          Navigator.pop(ctx);

          if (!mounted) return;
          if (success) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.adminProducts,
              (_) => false,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al guardar el producto. Revisa la consola.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteProduct(String id, String nombre) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('Eliminar producto'),
              ],
            ),
            content: Text(
              '¿Eliminar "$nombre"? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    final success = await _productService.deleteProduct(id);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.adminProducts,
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar el producto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // BaseLayout usa SingleChildScrollView internamente → restricciones verticales
    // ilimitadas → NO usar Expanded ni ListView sin shrinkWrap aquí.
    return BaseLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPurple,
                  AppColors.primaryPurple.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Administración de Productos',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Gestiona el catálogo de Musilux',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _showProductForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryPurple,
                  ),
                ),
              ],
            ),
          ),

          // ── Lista de productos ─────────────────────────────────────────────
          FutureBuilder<List<ProductModel>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _refreshProducts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 60,
                    horizontal: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay productos registrados',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _showProductForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar primer producto'),
                      ),
                    ],
                  ),
                );
              }

              final products = snapshot.data!;
              // shrinkWrap + NeverScrollableScrollPhysics porque el scroll
              // externo ya lo maneja BaseLayout (SingleChildScrollView).
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                itemBuilder: (context, index) => _ProductCard(
                  product: products[index],
                  onEdit: () => _showProductForm(product: products[index]),
                  onDelete: () => _deleteProduct(
                    products[index].id!,
                    products[index].nombre,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD DE PRODUCTO
// ─────────────────────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  Color _tipoColor() {
    switch (product.tipoProducto) {
      case 'digital':
        return Colors.blue;
      case 'servicio':
        return Colors.orange;
      default:
        return Colors.green; // fisico
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imagenUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imagenUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image_outlined,
                          color: Colors.grey,
                        ),
                      ),
                      errorWidget: (_, __, ___) =>
                          _PlaceholderAvatar(product: product),
                    )
                  : _PlaceholderAvatar(product: product),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\$${product.precio.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _tipoColor().withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.tipoProducto,
                          style: TextStyle(
                            fontSize: 11,
                            color: _tipoColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stock: ${product.inventario}  •  ${product.estaActivo ? "Activo" : "Inactivo"}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Acciones
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: AppColors.primaryPurple,
                  ),
                  tooltip: 'Editar',
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Eliminar',
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  final ProductModel product;
  const _PlaceholderAvatar({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.primaryPurple.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          product.nombre.isNotEmpty ? product.nombre[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryPurple,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIÁLOGO DE FORMULARIO
// ─────────────────────────────────────────────────────────────────────────────
class ProductFormDialog extends StatefulWidget {
  final ProductModel? product;
  final Future<void> Function(ProductModel) onSave;

  const ProductFormDialog({super.key, this.product, required this.onSave});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _slugCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _precioCtrl;
  late TextEditingController _invCtrl;
  late TextEditingController _bpmCtrl;
  String _tipoProducto = 'fisico';
  int _idCategoria = 1;
  bool _estaActivo = true;

  YoutubeVideo? _selectedVideo;

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  String? _existingImageUrl;
  bool _isUploadingImage = false;
  bool _isSaving = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _slugCtrl = TextEditingController(text: p?.slug ?? '');
    _descCtrl = TextEditingController(text: p?.descripcion ?? '');
    _precioCtrl = TextEditingController(text: p?.precio.toString() ?? '');
    _invCtrl = TextEditingController(text: p?.inventario.toString() ?? '');
    _bpmCtrl = TextEditingController(text: p?.bpm?.toString() ?? '');
    _tipoProducto = p?.tipoProducto ?? 'fisico';
    _idCategoria = p?.idCategoria ?? 1;
    _estaActivo = p?.estaActivo ?? true;
    _existingImageUrl = p?.imagenUrl;

    if (p?.youtubeVideoId != null) {
      _selectedVideo = YoutubeVideo(
        videoId: p!.youtubeVideoId!,
        title: p.youtubeTitle ?? '',
        channel: p.youtubeChannel ?? '',
        thumbnail: p.youtubeThumbnail,
      );
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _slugCtrl.dispose();
    _descCtrl.dispose();
    _precioCtrl.dispose();
    _invCtrl.dispose();
    _bpmCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 88,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _pickedImageBytes = bytes;
        _existingImageUrl = null;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _isUploadingImage = _pickedImage != null;
    });

    String? finalImageUrl = _existingImageUrl;

    if (_pickedImage != null) {
      try {
        final folder =
            widget.product?.id ??
            'nuevo-${DateTime.now().millisecondsSinceEpoch}';
        finalImageUrl = await FirebaseStorageService.uploadProductImage(
          _pickedImage!,
          folder,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al subir imagen: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isSaving = false;
          _isUploadingImage = false;
        });
        return;
      }
    }

    setState(() => _isUploadingImage = false);

    final product = ProductModel(
      id: widget.product?.id,
      idCategoria: _idCategoria,
      nombre: _nombreCtrl.text.trim(),
      slug: _slugCtrl.text.trim(),
      descripcion: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      tipoProducto: _tipoProducto,
      precio: double.tryParse(_precioCtrl.text) ?? 0,
      inventario: int.tryParse(_invCtrl.text) ?? 0,
      bpm: int.tryParse(_bpmCtrl.text),
      estaActivo: _estaActivo,
      imagenUrl: finalImageUrl,
      youtubeVideoId: _selectedVideo?.videoId,
      youtubeTitle: _selectedVideo?.title,
      youtubeChannel: _selectedVideo?.channel,
      youtubeThumbnail: _selectedVideo?.thumbnail,
    );

    await widget.onSave(product);
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.product == null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header del diálogo ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurple,
                    AppColors.primaryPurple.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isNew ? Icons.add_box_outlined : Icons.edit_outlined,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isNew ? 'Nuevo Producto' : 'Editar Producto',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    tooltip: 'Cerrar',
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            // ── Contenido del formulario ────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Sección: Información básica ─────────────────────
                      _SectionHeader(
                        icon: Icons.info_outline,
                        label: 'Información básica',
                      ),
                      const SizedBox(height: 12),

                      _StyledField(
                        controller: _nombreCtrl,
                        label: 'Nombre del producto',
                        icon: Icons.label_outline,
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Requerido' : null,
                        onChanged: (val) {
                          if (isNew) {
                            _slugCtrl.text = val
                                .toLowerCase()
                                .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
                                .trim()
                                .replaceAll(' ', '-');
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      _StyledField(
                        controller: _slugCtrl,
                        label: 'Slug (URL)',
                        icon: Icons.link,
                        helperText: 'Generado automáticamente por el servidor',
                      ),
                      const SizedBox(height: 12),

                      // Categoría
                      DropdownButtonFormField<int>(
                        value: _idCategoria,
                        decoration: InputDecoration(
                          labelText: 'Categoría',
                          prefixIcon: const Icon(Icons.folder_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('Instrumentos'),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('Iluminación'),
                          ),
                          DropdownMenuItem(value: 3, child: Text('Vinilos')),
                        ],
                        onChanged: (v) => setState(() => _idCategoria = v!),
                      ),
                      const SizedBox(height: 12),

                      // Tipo de producto
                      DropdownButtonFormField<String>(
                        value: _tipoProducto,
                        decoration: InputDecoration(
                          labelText: 'Tipo de producto',
                          prefixIcon: const Icon(Icons.category_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'fisico',
                            child: Text('Físico (vinilo, instrumento)'),
                          ),
                          DropdownMenuItem(
                            value: 'digital',
                            child: Text('Digital (audio/descarga)'),
                          ),
                          DropdownMenuItem(
                            value: 'servicio',
                            child: Text('Servicio'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _tipoProducto = v!),
                      ),
                      const SizedBox(height: 12),

                      _StyledField(
                        controller: _descCtrl,
                        label: 'Descripción',
                        icon: Icons.notes,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),

                      // ── Sección: Precio y stock ─────────────────────────
                      _SectionHeader(
                        icon: Icons.attach_money,
                        label: 'Precio y stock',
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _StyledField(
                              controller: _precioCtrl,
                              label: 'Precio (\$)',
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v!.isEmpty) return 'Requerido';
                                if (double.tryParse(v) == null)
                                  return 'Número inválido';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StyledField(
                              controller: _invCtrl,
                              label: 'Inventario',
                              icon: Icons.inventory_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v!.isEmpty) return 'Requerido';
                                if (int.tryParse(v) == null)
                                  return 'Número inválido';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _StyledField(
                        controller: _bpmCtrl,
                        label: 'BPM (opcional)',
                        icon: Icons.speed,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),

                      // Toggle activo
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          title: const Text('Producto activo'),
                          subtitle: Text(
                            _estaActivo
                                ? 'Visible en el catálogo'
                                : 'Oculto del catálogo',
                            style: TextStyle(
                              fontSize: 12,
                              color: _estaActivo ? Colors.green : Colors.grey,
                            ),
                          ),
                          value: _estaActivo,
                          activeColor: AppColors.primaryPurple,
                          onChanged: (v) => setState(() => _estaActivo = v),
                        ),
                      ),

                      // ── Sección: Imagen ─────────────────────────────────
                      const SizedBox(height: 20),
                      _SectionHeader(
                        icon: Icons.image_outlined,
                        label: 'Imagen del producto',
                      ),
                      const SizedBox(height: 12),

                      _ImagePickerSection(
                        pickedImageBytes: _pickedImageBytes,
                        existingImageUrl: _existingImageUrl,
                        isUploading: _isUploadingImage,
                        onPick: _pickImage,
                        onRemove: () => setState(() {
                          _pickedImage = null;
                          _pickedImageBytes = null;
                          _existingImageUrl = null;
                        }),
                      ),

                      // ── Sección: YouTube ─────────────────────────────────
                      YoutubeSearchWidget(
                        initialVideo: _selectedVideo,
                        onVideoSelected: (v) =>
                            setState(() => _selectedVideo = v),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer con botones ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(isNew ? Icons.add : Icons.save),
                    label: Text(
                      _isUploadingImage
                          ? 'Subiendo imagen...'
                          : _isSaving
                          ? 'Guardando...'
                          : isNew
                          ? 'Crear producto'
                          : 'Guardar cambios',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────────────────────────

/// Encabezado de sección dentro del formulario.
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryPurple),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.primaryPurple,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(color: AppColors.primaryPurple.withValues(alpha: 0.2)),
        ),
      ],
    );
  }
}

/// Campo de texto con estilo uniforme.
class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final String? helperText;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

/// Sección de imagen: muestra preview o botón de selección.
class _ImagePickerSection extends StatelessWidget {
  final Uint8List? pickedImageBytes;
  final String? existingImageUrl;
  final bool isUploading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImagePickerSection({
    required this.pickedImageBytes,
    required this.existingImageUrl,
    required this.isUploading,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Imagen nueva seleccionada localmente
    if (pickedImageBytes != null) {
      return _ImagePreview(
        child: Image.memory(
          pickedImageBytes!,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        onRemove: onRemove,
      );
    }

    // URL existente en Firebase
    if (existingImageUrl != null) {
      return _ImagePreview(
        child: CachedNetworkImage(
          imageUrl: existingImageUrl!,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (_, __, ___) => Container(
            height: 160,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
        onRemove: onRemove,
      );
    }

    // Sin imagen — área de selección moderna con borde punteado
    return GestureDetector(
      onTap: isUploading ? null : onPick,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 130,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: isUploading ? Colors.grey.shade300 : Colors.grey.shade400,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isUploading ? Colors.grey.shade100 : Colors.grey.shade50,
        ),
        child: isUploading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 32,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Toca para seleccionar imagen',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PNG, JPG — máx. 5 MB',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Wrapper de preview de imagen con botón de eliminar superpuesto.
class _ImagePreview extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;

  const _ImagePreview({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(height: 160, width: double.infinity, child: child),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.white),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}
