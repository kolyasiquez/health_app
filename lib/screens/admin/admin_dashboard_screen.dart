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

  @override
  void initState() {
    super.initState();
    _fetchPendingDoctors();
  }

  // Отримуємо список лікарів, що очікують
  Future<void> _fetchPendingDoctors() async {
    setState(() { _isLoading = true; });
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
      setState(() { _isLoading = false; });
    }
  }

  // Схвалюємо лікаря
  Future<void> _approveDoctor(String uid) async {
    try {
      await _apiService.approveDoctor(uid);
      // Оновлюємо UI, видаляючи лікаря зі списку
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
    }
  }

  // Відхиляємо лікаря
  Future<void> _denyDoctor(String uid) async {
    try {
      // ⚠️ ВАЖЛИВА ПРИМІТКА:
      // Цей метод видаляє ТІЛЬКИ дані з Firestore (patients/doctors/user_roles).
      // Він НЕ видаляє акаунт з Firebase Authentication.
      // Вам доведеться робити це вручну через консоль Firebase.
      await _apiService.denyDoctor(uid);

      setState(() {
        _pendingDoctors.removeWhere((doc) => doc.id == uid);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заявку лікаря відхилено. Дані видалено.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      log('Помилка відхилення: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Адмін-панель'),
        actions: [
          // Кнопка оновлення списку
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPendingDoctors,
          ),
          // Кнопка виходу
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
          : _pendingDoctors.isEmpty
          ? Center(
        child: Text(
          'Немає заявок на верифікацію.',
          style: theme.textTheme.titleMedium,
        ),
      )
          : ListView.builder(
        itemCount: _pendingDoctors.length,
        itemBuilder: (context, index) {
          final doctor = _pendingDoctors[index];
          final data = doctor.data() as Map<String, dynamic>;

          // Використовуємо ExpansionTile, щоб показати 'bio'
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  data['name']?.substring(0, 1) ?? '?',
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(data['name'] ?? 'Без імені', style: theme.textTheme.titleMedium),
              subtitle: Text(data['email'] ?? 'Без пошти'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Біографія (кваліфікація, досвід):', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        data['bio'] ?? 'Не вказано',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      // Кнопки дій
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
                            ),
                            child: const Text('Схвалити'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Діалог підтвердження перед видаленням
  void _showDenyDialog(String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Підтвердити дію'),
        content: const Text(
          'Ви впевнені, що хочете відхилити цього лікаря? Його дані буде видалено з бази.\n\n(Примітка: акаунт входу (Authentication) потрібно буде видалити вручну в консолі Firebase.)',
        ),
        actions: [
          TextButton(
            child: const Text('Скасувати'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Відхилити'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _denyDoctor(uid);
            },
          ),
        ],
      ),
    );
  }
}