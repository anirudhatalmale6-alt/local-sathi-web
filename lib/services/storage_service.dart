import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload Aadhaar document image
  Future<String> uploadAadhaarDoc(String uid, XFile imageFile) async {
    final ref = _storage.ref().child('aadhaar_docs/$uid.jpg');

    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      await ref.putFile(File(imageFile.path));
    }

    return await ref.getDownloadURL();
  }

  /// Upload profile photo
  Future<String> uploadProfilePhoto(String uid, XFile imageFile) async {
    final ref = _storage.ref().child('profile_photos/$uid.jpg');

    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      await ref.putFile(File(imageFile.path));
    }

    return await ref.getDownloadURL();
  }
}
