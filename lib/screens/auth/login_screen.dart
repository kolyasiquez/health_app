// lib/screens/auth/login_screen.dart

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:health_app/screens/auth/auth_service.dart';
import 'package:health_app/services/api_service.dart'; // 🚀 ІМПОРТУЄМО API SERVICE

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _apiService = ApiService(); // 🚀 ІНІЦІАЛІЗУЄМО API SERVICE

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 🚀 СТАН ДЛЯ ЗАВАНТАЖЕННЯ
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = theme.colorScheme.primary;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100), // Додамо відступ зверху
              Icon(Icons.favorite, size: 100, color: primaryTeal),
              const SizedBox(height: 20),
              Text(
                'Мобільний медичний помічник',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Електронна пошта',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                // 🚀 Блокуємо кнопку під час завантаження
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : const Text('Увійти'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                  Navigator.pushNamed(context, '/registration');
                },
                child: const Text(
                  'Зареєструватися',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🚀🚀🚀 ОНОВЛЕНА ЛОГІКА ВХОДУ З ПЕРЕВІРКОЮ РОЛІ 🚀🚀🚀
  _login() async {
    setState(() { _isLoading = true; });

    try {
      // 1. ВХІД В FIREBASE AUTH
      final user = await _auth.loginUserWithEmailAndPassword(
          _emailController.text.trim(), _passwordController.text);

      if (user != null && mounted) {
        log("User logged in successfully: ${user.uid}");

        // 2. ОТРИМАННЯ ДАНИХ КОРИСТУВАЧА (І РОЛІ) З FIRESTORE
        final userData = await _apiService.getUserData();

        if (userData == null) {
          // Якщо користувач є в Auth, але немає в Firestore (напр. видалено адміном)
          await _auth.signOut(); // Виходимо з системи
          throw Exception("Профіль користувача не знайдено. Можливо, його було видалено.");
        }

        final String role = userData['role'];
        log("User role is: $role");

        // 3. ПЕРЕНАПРАВЛЕННЯ НА ОСНОВІ РОЛІ
        switch (role) {
          case 'patient':
            Navigator.pushReplacementNamed(context, '/patient_dashboard');
            break;
          case 'doctor':
            Navigator.pushReplacementNamed(context, '/doctor_dashboard');
            break;
          case 'pending_doctor': // 🚀 НОВИЙ ВИПАДОК
            Navigator.pushReplacementNamed(context, '/pending_verification');
            break;
          case 'admin':
          // TODO: Створити /admin_dashboard
            Navigator.pushReplacementNamed(context, '/doctor_dashboard');
            break;
          default:
            throw Exception("Невідома роль користувача: $role");
        }
      }
    } catch (e) {
      // 4. ОБРОБКА ПОМИЛОК
      log("Login failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка входу: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }
}