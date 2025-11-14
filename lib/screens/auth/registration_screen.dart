// lib/screens/auth/registration_screen.dart

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:health_app/screens/auth/auth_service.dart';
import 'package:health_app/services/api_service.dart';

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
  final _bioController = TextEditingController(); // 🚀 ДЛЯ БІОГРАФІЇ ЛІКАРЯ

  UserRole _selectedRole = UserRole.patient;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bioController.dispose();
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
              const SizedBox(height: 60),
              Icon(Icons.favorite, size: 100, color: primaryTeal),
              const SizedBox(height: 20),
              Text(
                'Create account',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              SegmentedButton<UserRole>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: primaryTeal.withOpacity(0.1),
                  selectedForegroundColor: primaryTeal,
                  foregroundColor: theme.textTheme.bodyMedium?.color,
                ),
                segments: const [
                  ButtonSegment<UserRole>(
                    value: UserRole.patient,
                    label: Text('I am a patient'),
                    icon: Icon(Icons.person_outline),
                  ),
                  ButtonSegment<UserRole>(
                    value: UserRole.doctor,
                    label: Text('I am a doctor'),
                    icon: Icon(Icons.medical_services_outlined),
                  ),
                ],
                selected: {_selectedRole},
                onSelectionChanged: (Set<UserRole> newSelection) {
                  setState(() {
                    _selectedRole = newSelection.first;
                  });
                },
              ),

              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Repeat the password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),

              // 🚀🚀🚀 ОНОВЛЕНІ ПОЛЯ ДЛЯ ЛІКАРЯ (ТІЛЬКИ ТЕКСТ) 🚀🚀🚀
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                firstChild: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Поле для Біографії
                    TextField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'About me (experience, certificate links etc.)',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
                secondChild: Container(), // Порожній контейнер
                crossFadeState: _selectedRole == UserRole.doctor
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
              ),
              // 🚀🚀🚀 КІНЕЦЬ БЛОКУ ДЛЯ ЛІКАРЯ 🚀🚀🚀

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                child: _isLoading
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : const Text('Sign up'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text(
                  'Already have an account? Sign in',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🚀🚀🚀 СПРОЩЕНА ЛОГІКА РЕЄСТРАЦІЇ 🚀🚀🚀
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

    // 2. ДОДАТКОВА ПЕРЕВІРКА ДЛЯ ЛІКАРЯ
    if (_selectedRole == UserRole.doctor) {
      if (_bioController.text.trim().isEmpty) { // 🚀 Перевіряємо тільки 'bio'
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Будь ласка, заповніть інформацію про себе.')),
          );
        }
        return;
      }
    }

    setState(() { _isLoading = true; });

    try {
      // 3. СТВОРЮЄМО КОРИСТУВАЧА. 'bio' передається одразу.
      final user = await _auth.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _selectedRole,
        // 🚀 Передаємо 'bio' тільки якщо це лікар
        bio: _selectedRole == UserRole.doctor
            ? _bioController.text.trim()
            : null,
      );

      if (user == null) {
        throw Exception("Не вдалося створити користувача.");
      }

      // 4. ОБРОБКА ЗАЛЕЖНО ВІД РОЛІ
      if (_selectedRole == UserRole.doctor) {
        // 4а. ЛІКАР: Все готово, перекидаємо на верифікацію
        log("Doctor created, pending verification.");
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/pending_verification');
        }

      } else {
        // 4б. ПАЦІЄНТ: Все готово, перекидаємо на дашборд
        log("Patient created successfully.");
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/patient_dashboard');
        }
      }

    } catch (e) {
      log("Registration failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка реєстрації: ${e.toString()}')),
        );
      }
    } finally {
      if(mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }
}