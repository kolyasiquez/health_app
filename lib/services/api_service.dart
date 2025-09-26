// lib/services/api_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ApiService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  // Метод для отримання даних користувача з Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  // *** ВИПРАВЛЕНО (НОВИЙ МЕТОД): Оновлює лише документ користувача в Firestore ***
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update(data);
  }

  // *** ВИПРАВЛЕНО: Тепер повертає String? (URL), а не void ***
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null; // Повертаємо null, якщо немає користувача

      final path = 'avatars/${user.uid}.jpg';
      final ref = _storage.ref().child(path);

      // Завантажуємо файл
      final uploadTask = await ref.putFile(imageFile);

      // Отримуємо та повертаємо URL-адресу
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // *** ВИДАЛЕНО: Оновлення профілю перенесено у health_profile_screen ***

      return imageUrl;

    } catch (e) {
      print("Error uploading file: $e");
      return null; // Повертаємо null у разі помилки
    }
  }

// ... інші методи ...
}