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

  final _formKey = GlobalKey<FormState>();

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
            child: Form(
              key: _formKey,
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
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Ім\'я',
                      prefixIcon: Icon(Icons.person, color: Colors.deepPurpleAccent),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Будь ласка, введіть ім\'я';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Електронна пошта',
                      prefixIcon: Icon(Icons.email, color: Colors.deepPurpleAccent),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Будь ласка, введіть електронну пошту';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Пароль',
                      prefixIcon: Icon(Icons.lock, color: Colors.deepPurpleAccent),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Будь ласка, введіть пароль';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Підтвердіть пароль',
                      prefixIcon: Icon(Icons.lock, color: Colors.deepPurpleAccent),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Паролі не збігаються';
                      }
                      return null;
                    },
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
      ),
    );
  }

  _signup() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      log("Attempting to register user...");

      final result = await _auth.registerUserWithEmailAndPassword(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      log("Received result from AuthService: $result");

      if (result != null) {
        log("User has been created successfully");
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/patient_dashboard');
        }
      } else {
        log("Registration failed");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to register. Please try again.'),
            ),
          );
        }
      }
    }
  }
}
