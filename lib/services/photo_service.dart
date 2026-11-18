import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Picks a document photo (camera or gallery) and copies it into the
/// app's private documents directory, so it survives the original
/// gallery image being moved or deleted. Returns the stored file path.
class PhotoService {
  PhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pickAndStore(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return storeFile(File(picked.path));
  }

  Future<String> storeFile(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final ext = p.extension(file.path).isEmpty
        ? '.jpg'
        : p.extension(file.path);
    final name =
        '${DateTime.now().millisecondsSinceEpoch}'
        '_${file.path.hashCode.abs()}$ext';
    final stored = await file.copy(p.join(photosDir.path, name));
    return stored.path;
  }

  Future<void> deletePhoto(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
