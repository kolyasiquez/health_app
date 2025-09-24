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
                  'Мобільний медичний помічник',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
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
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: Colors.deepPurpleAccent),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _login, // Викликаємо метод _login()
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                  ),
                  child: const Text('Увійти'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/registration');
                  },
                  child: Text(
                    'Зареєструватися',
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

  _login() async {
    final user = await _auth.loginUserWithEmailAndPassword(
        _emailController.text, _passwordController.text);
    if (user != null) {
      log("User logged in successfully");
      // Перенаправляємо користувача тільки після успішного входу
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/patient_dashboard');
      }
    } else {
      // Обробка помилки входу
      log("Login failed");
      // Ви можете тут показати SnackBar з повідомленням про помилку
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Помилка входу. Перевірте пошту та пароль.')),
      );
    }
  }
}