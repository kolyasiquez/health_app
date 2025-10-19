// lib/screens/admin/admin_dashboard_screen.dart

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';
import 'package:health_app/screens/auth/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _pendingDoctors = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPendingDoctors();
  }

  Future<void> _fetchPendingDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final snapshot = await _apiService.getPendingDoctors();
      setState(() {
        _pendingDoctors = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      log('Помилка завантаження лікарів: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка завантаження даних: $e')),
        );
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Помилка завантаження: $e \n\n(Перевірте Debug Console на посилання для створення індексу Firestore!)';
      });
    }
  }

  Future<void> _approveDoctor(String uid) async {
    try {
      await _apiService.approveDoctor(uid);
      setState(() {
        _pendingDoctors.removeWhere((doc) => doc.id == uid);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Лікаря схвалено.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      log('Помилка схвалення: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка схвалення: $e')),
        );
      }
    }
  }

  // 🚀🚀🚀 ОНОВЛЕНИЙ МЕТОД _denyDoctor - ЗНОВУ ВИКЛИКАЄ ВИДАЛЕННЯ 🚀🚀🚀
  // Відхиляємо лікаря та видаляємо його дані з Firestore
  Future<void> _denyDoctor(String uid) async {
    try {
      // Викликаємо метод сервісу для видалення документів Firestore
      await _apiService.denyDoctor(uid);

      // Оновлюємо UI
      setState(() {
        _pendingDoctors.removeWhere((doc) => doc.id == uid);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Лікаря відхилено. Дані профілю видалено.'),
            backgroundColor: Colors.red, // Повертаємо червоний колір
          ),
        );
      }
    } catch (e) {
      log('Помилка відхилення та видалення: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка видалення даних: $e')),
        );
      }
    }
  }
  // 🚀🚀🚀 КІНЕЦЬ ОНОВЛЕННЯ 🚀🚀🚀


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Адмін-панель'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPendingDoctors,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDoctorList(theme),
    );
  }

  Widget _buildDoctorList(ThemeData theme) {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_pendingDoctors.isEmpty) {
      return Center(
        child: Text(
          'Немає заявок на верифікацію.',
          style: theme.textTheme.titleMedium,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _pendingDoctors.length,
      itemBuilder: (context, index) {
        final doctor = _pendingDoctors[index];
        final data = doctor.data() as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        data['name']?.substring(0, 1) ?? '?',
                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'] ?? 'Без імені', style: theme.textTheme.titleMedium),
                          Text(data['email'] ?? 'Без пошти', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24.0),
                Text(
                    'Біографія (кваліфікація, досвід):',
                    style: theme.textTheme.bodySmall
                ),
                const SizedBox(height: 4),
                Text(
                  data['bio'] ?? 'Не вказано',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _showDenyDialog(doctor.id),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Відхилити'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _approveDoctor(doctor.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 36), // ВАЖЛИВО: Залишити це виправлення
                      ),
                      child: const Text('Схвалити'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🚀🚀🚀 ОНОВЛЕНИЙ ДІАЛОГ _showDenyDialog 🚀🚀🚀
  // Діалог підтвердження перед видаленням даних
  void _showDenyDialog(String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Підтвердити видалення'), // Оновлено
        content: const Text(
          'Ви впевнені, що хочете відхилити та видалити дані цього лікаря з бази?\n\n(ВАЖЛИВО: Після цього вам потрібно буде вручну видалити його акаунт з Firebase Authentication.)', // Оновлено
        ),
        actions: [
          TextButton(
            child: const Text('Скасувати'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red), // Повертаємо червоний
            child: const Text('Видалити дані'), // Оновлено
            onPressed: () {
              Navigator.of(ctx).pop();
              _denyDoctor(uid); // Викликаємо оновлений метод
            },
          ),
        ],
      ),
    );
  }
// 🚀🚀🚀 КІНЕЦЬ ОНОВЛЕННЯ 🚀🚀🚀
}