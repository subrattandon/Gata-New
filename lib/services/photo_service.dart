import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Picks images and copies them into the app's documents directory so the
/// path stays valid after the OS clears the picker's temp cache.
///
/// Uses the Android Photo Picker under the hood (no runtime permission needed).
/// When Firebase lands, this is where uploads to Firebase Storage slot in.
class PhotoService {
  static final _picker = ImagePicker();
  static const _uuid = Uuid();

  static Future<String?> pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        imageQuality: 88,
      );
      if (file == null) return null;
      return _persist(file);
    } catch (e) {
      debugPrint('PhotoService.pickFromGallery error: $e');
      return null;
    }
  }

  static Future<String?> pickFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        imageQuality: 88,
      );
      if (file == null) return null;
      return _persist(file);
    } catch (e) {
      debugPrint('PhotoService.pickFromCamera error: $e');
      return null;
    }
  }

  static Future<String> _persist(XFile file) async {
    final dir = await getApplicationDocumentsDirectory();
    final photos = Directory('${dir.path}/photos');
    if (!await photos.exists()) await photos.create(recursive: true);
    final ext = file.path.split('.').last;
    final dest = '${photos.path}/${_uuid.v4()}.$ext';
    await File(file.path).copy(dest);
    return dest;
  }
}
