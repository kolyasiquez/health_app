// lib/screens/auth/login_screen.dart

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:health_app/screens/auth/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
                'Мобільний медичний помічник',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // 🚀 Поля введення використовують нову InputDecorationTheme
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
              const SizedBox(height: 30),
              // 🚀 Кнопка використовує ElevatedButtonTheme (помаранчевий)
              ElevatedButton(
                onPressed: _login,
                child: const Text('Увійти'),
              ),
              const SizedBox(height: 10),
              // 🚀 TextButton використовує TextButtonTheme (бірюзовий)
              TextButton(
                onPressed: () {
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

  _login() async {
    final user = await _auth.loginUserWithEmailAndPassword(
        _emailController.text, _passwordController.text);
    if (user != null) {
      log("User logged in successfully");
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/patient_dashboard');
      }
    } else {
      log("Login failed");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Помилка входу. Перевірте пошту та пароль.')),
        );
      }
    }
  }
}