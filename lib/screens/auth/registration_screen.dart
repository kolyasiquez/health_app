// lib/screens/auth/registration_screen.dart

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
    final theme = Theme.of(context);
    final primaryTeal = theme.colorScheme.primary;

    return Scaffold(
      // 🚀 Використовуємо світлий фон Scaffold з теми
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🚀 Іконка тепер бірюзова
              Icon(Icons.favorite, size: 100, color: primaryTeal),
              const SizedBox(height: 20),
              Text(
                'Створити акаунт',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // 🚀 Поля введення використовують нову InputDecorationTheme
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ім\'я',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
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
              const SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Підтвердіть пароль',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 30),
              // 🚀 Кнопка використовує ElevatedButtonTheme (помаранчевий)
              ElevatedButton(
                onPressed: _signup,
                child: const Text('Зареєструватися'),
              ),
              const SizedBox(height: 10),
              // 🚀 TextButton використовує TextButtonTheme (бірюзовий)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Вже маєте акаунт? Увійти',
                ),
              ),
            ],
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
        _nameController.text
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Помилка реєстрації. Перевірте email або пароль (мінімум 6 символів).')),
        );
      }
    }
  }
}