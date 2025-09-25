// lib/services/api_service.dart (або user_service.dart)

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ApiService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  // ... інші методи ...

  Future<void> uploadAvatar(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final path = 'avatars/${user.uid}.jpg';
      final ref = _storage.ref().child(path);

      // Завантажуємо файл
      final uploadTask = await ref.putFile(imageFile);

      // Отримуємо URL-адресу завантаженого файлу
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // Оновлюємо документ користувача в Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'avatarUrl': imageUrl,
      });

    } catch (e) {
      // Обробка помилки завантаження
      print("Error uploading avatar: $e");
    }
  }

  // Метод для отримання даних користувача з Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }
}