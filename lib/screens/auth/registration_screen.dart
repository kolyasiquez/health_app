// lib/screens/auth/registration_screen.dart (Оновлений код)

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:health_app/screens/auth/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (UI залишається без змін)
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF121212), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, size: 100, color: Colors.deepPurpleAccent),
                const SizedBox(height: 20),
                Text(
                  'Створити акаунт',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ім\'я',
                    prefixIcon: Icon(Icons.person, color: Colors.deepPurpleAccent),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Електронна пошта',
                    prefixIcon: Icon(Icons.email, color: Colors.deepPurpleAccent),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Пароль',
                    prefixIcon: Icon(Icons.lock, color: Colors.deepPurpleAccent),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Підтвердіть пароль',
                    prefixIcon: Icon(Icons.lock, color: Colors.deepPurpleAccent),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                  ),
                  child: const Text('Зареєструватися'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Вже маєте акаунт? Увійти',
                    style: TextStyle(color: Colors.deepPurpleAccent.shade200),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🚀 ОНОВЛЕНА ЛОГІКА РЕЄСТРАЦІЇ
  _signup() async {
    // 1. ПЕРЕВІРКА ПАРОЛІВ
    if (_passwordController.text != _confirmPasswordController.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Помилка: Паролі не співпадають.')),
        );
      }
      return;
    }

    // 2. ВИКЛИК СЕРВІСУ З ІМ'ЯМ
    final user = await _auth.createUserWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
        _nameController.text // 🚀 Передаємо ім'я
    );

    if (user != null) {
      log("User has been created successfully and profile document saved.");
      if (mounted) {
        // Успішна реєстрація та створення профілю
        Navigator.pushReplacementNamed(context, '/patient_dashboard');
      }
    } else {
      // 3. ОБРОБКА ПОМИЛОК
      log("Registration failed, user object is null.");
      if (mounted) {
        // Показуємо загальну помилку, деталі обробляються в AuthService
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Помилка реєстрації. Перевірте email або пароль (мінімум 6 символів).')),
        );
      }
    }
  }
}