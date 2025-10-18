// lib/screens/auth/auth_service.dart

import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart'; // 🚀 ІМПОРТУЄМО (і UserRole)

class AuthService {
  final _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService(); // 🚀 ІНІЦІАЛІЗУЄМО

  // 🚀 ОНОВЛЕНО: Тепер приймає 'bio' як необов'язковий іменований параметр
  Future<User?> createUserWithEmailAndPassword(
      String email, String password, String name, UserRole role, {String? bio}) async {
    try {
      // 🚀 ПЕРЕВІРКА ЛІМІТУ АДМІНІВ (якщо це реєстрація адміна)
      if (role == UserRole.admin) {
        await _apiService.checkAdminLimit();
      }

      // 1. Створюємо користувача в Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = cred.user;

      if (user != null) {
        // 2. КЛЮЧОВИЙ КРОК: Створення документа профілю в Firestore
        //    Передаємо 'bio' в ApiService
        await _apiService.createUserDocument(user.uid, email, name, role, bio: bio);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      log("Registration failed: ${e.message}");
      // Перекидаємо помилку, щоб UI міг її обробити
      rethrow;
    } catch (e) {
      log("Something went wrong during registration: $e");
      rethrow;
    }
  }

  // Метод входу залишається без змін.
  Future<User?> loginUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred =
      await _auth.signInWithEmailAndPassword(email: email, password: password);
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