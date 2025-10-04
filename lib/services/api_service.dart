// lib/services/api_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Більше не потрібен 'package:firebase_storage/firebase_storage.dart';

class ApiService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // This method is for creating a user document in Firestore (users collection at this moment)
  Future<void> createUserDocument(String uid, String email, String name) async {
    const String defaultAvatarPath = 'assets/images/default_person.png'; // Put default avatar

    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'avatarUrl': defaultAvatarPath,
      'age': null,
    });
  }

  // Method for getting user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  // Метод для оновлення документа користувача в Firestore
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User is not signed in.");
    }

    if (data.isNotEmpty) {
      // Використовуємо update, оскільки ми гарантували створення документа
      await _firestore.collection('users').doc(user.uid).update(data);
    }
  }
}