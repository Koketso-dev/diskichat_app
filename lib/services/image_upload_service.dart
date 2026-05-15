import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<String> uploadImage(File file, {String folder = 'posts'}) async {
    try {
      final compressedFile = await _compressImage(file);
      final File uploadFile = compressedFile ?? file;

      final String fileName = '${_uuid.v4()}.jpg';
      final Reference ref = _storage.ref().child(folder).child(fileName);

      final TaskSnapshot snapshot = await ref.putFile(
        uploadFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String> uploadVideo(File file, {String folder = 'posts/videos'}) async {
    try {
      final String fileName = '${_uuid.v4()}.mp4';
      final Reference ref = _storage.ref().child(folder).child(fileName);

      final TaskSnapshot snapshot = await ref.putFile(
        file,
        SettableMetadata(contentType: 'video/mp4'),
      );

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final String targetPath = '${dir.path}/${_uuid.v4()}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1080,
        minHeight: 1080,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      debugPrint("Image compression failed: $e");
      return null;
    }
  }
}
