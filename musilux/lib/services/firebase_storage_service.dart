import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube una imagen a Firebase Storage y retorna la URL de descarga.
  /// Usa putData(bytes) para compatibilidad con Web y Android.
  static Future<String> uploadProductImage(XFile imageFile, String productId) async {
    final bytes = await imageFile.readAsBytes();
    final extension = imageFile.name.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('productos/$productId/$timestamp.$extension');

    await ref.putData(bytes, SettableMetadata(contentType: 'image/$extension'));

    return await ref.getDownloadURL();
  }
}
