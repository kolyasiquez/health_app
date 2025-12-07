import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_app/services/api_service.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();

  // 🚀 ОНОВЛЕНО: Додано параметр phoneNumber як обов'язковий
  Future<User?> createUserWithEmailAndPassword(
      String email,
      String password,
      String name,
      UserRole role, {
        required String phoneNumber, // 👈 ОБОВ'ЯЗКОВИЙ
        String? bio,
        String? specialization,
      }) async {
    try {
      if (role == UserRole.admin) {
        await _apiService.checkAdminLimit();
      }

      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = cred.user;

      if (user != null) {
        // 🚀 ПЕРЕДАЄМО phoneNumber ДАЛІ В API SERVICE
        await _apiService.createUserDocument(
          user.uid,
          email,
          name,
          phoneNumber, // 👈 ПЕРЕДАЄМО ТУТ
          role,
          bio: bio,
          specialization: specialization,
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