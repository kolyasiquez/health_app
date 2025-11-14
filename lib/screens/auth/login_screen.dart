// lib/screens/auth/login_screen.dart

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:health_app/screens/auth/auth_service.dart';
import 'package:health_app/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _apiService = ApiService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
              const SizedBox(height: 100),
              Icon(Icons.favorite, size: 100, color: primaryTeal),
              const SizedBox(height: 20),
              Text(
                'Health-app',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : const Text('Sign in'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                  Navigator.pushNamed(context, '/registration');
                },
                child: const Text(
                  'Sign up',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _login() async {
    setState(() { _isLoading = true; });

    try {
      final user = await _auth.loginUserWithEmailAndPassword(
          _emailController.text.trim(), _passwordController.text);

      if (user != null && mounted) {
        log("User logged in successfully: ${user.uid}");
        final userData = await _apiService.getUserData();

        if (userData == null) {
          await _auth.signOut();
          throw Exception("Профіль користувача не знайдено. Можливо, його було видалено.");
        }

        final String role = userData['role'];
        log("User role is: $role");

        // 🚀 ОНОВЛЕНА ЛОГІКА НАВІГАЦІЇ
        switch (role) {
          case 'patient':
            Navigator.pushReplacementNamed(context, '/patient_dashboard');
            break;
          case 'doctor':
            Navigator.pushReplacementNamed(context, '/doctor_dashboard');
            break;
          case 'pending_doctor':
            Navigator.pushReplacementNamed(context, '/pending_verification');
            break;
          case 'admin':
          // 🚀 Тепер перенаправляє на новий екран адміна
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
            break;
          default:
            throw Exception("Невідома роль користувача: $role");
        }
      }
    } catch (e) {
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