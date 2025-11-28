// lib/screens/auth/auth_service.dart

import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();

  // 🚀 ОНОВЛЕНО: Додано параметр specialization
  Future<User?> createUserWithEmailAndPassword(
      String email,
      String password,
      String name,
      UserRole role, {
        String? bio,
        String? specialization, // 👈 ПРИЙМАЄМО ТУТ
      }) async {
    try {
      if (role == UserRole.admin) {
        await _apiService.checkAdminLimit();
      }

      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = cred.user;

      if (user != null) {
        // 🚀 ПЕРЕДАЄМО ДАЛІ В API SERVICE
        await _apiService.createUserDocument(
          user.uid,
          email,
          name,
          role,
          bio: bio,
          specialization: specialization, // 👈 ПЕРЕДАЄМО ТУТ
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      log("Registration failed: ${e.message}");
      rethrow;
    } catch (e) {
      log("Something went wrong during registration: $e");
      rethrow;
    }
  }

  Future<User?> loginUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      log("Login failed: ${e.message}");
      rethrow;
    } catch (e) {
      log("Something went wrong during login: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      log("Something went wrong during sign out: $e");
    }
  }
}