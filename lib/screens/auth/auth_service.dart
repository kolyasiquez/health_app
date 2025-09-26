// lib/screens/auth/auth_service.dart

import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart'; // 🚀 ІМПОРТУЄМО

class AuthService {
  final _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService(); // 🚀 ІНІЦІАЛІЗУЄМО

  // 🚀 ОНОВЛЕНИЙ МЕТОД РЕЄСТРАЦІЇ
  Future<User?> createUserWithEmailAndPassword(String email, String password, String name) async {
    try{
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = cred.user;

      if (user != null) {
        // КЛЮЧОВИЙ КРОК: Створення документа профілю в Firestore
        await _apiService.createUserDocument(user.uid, email, name);
      }
      return user;
    } on FirebaseAuthException catch(e){
      // Використовуйте e.message для кращої обробки помилок у UI
      log("Registration failed: ${e.message}");
    } catch(e){
      log("Something went wrong during registration: $e");
    }
    return null;
  }

  Future<User?> loginUserWithEmailAndPassword(String email, String password) async {
    try{
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch(e){
      log("Login failed: ${e.message}");
    } catch(e){
      log("Something went wrong during login");
    }
    return null;
  }

  Future<void> signOut() async {
    try{
      await _auth.signOut();
    }catch(e){
      log("Something went wrong during sign out");
    }
  }
}