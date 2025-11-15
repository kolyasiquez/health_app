import 'package:flutter/material.dart';
// 🚀 1. ДОДАНО ІМПОРТИ ДЛЯ FIREBASE ТА ДАТ
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:health_app/services/api_service.dart';
// 🚀 2. ДОДАНО ІМПОРТИ ЕКРАНІВ, НА ЯКІ ПЕРЕХОДИМО
import 'package:health_app/screens/patient/health_profile_screen.dart';
// (Переконайтеся, що цей шлях правильний)
import 'package:health_app/screens/patient/book_appointment_screen.dart';


class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  // --- 3. ДОДАНО FIREBASE AUTH/FIRESTORE ---
  final ApiService _apiService = ApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _avatarUrl;
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  /// Завантажує ім'я користувача та URL аватарки
  Future<void> _loadProfileData() async {
    // Припускаємо, що getUserData() повертає дані залогіненого юзера (пацієнта)
    final userData = await _apiService.getUserData();
    if (mounted) {
      setState(() {
        _avatarUrl = userData?['avatarUrl'];
        _userName = userData?['name'] ?? 'Пацієнт';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentOrange = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _buildHeader(context), // Використовуємо хедер
        toolbarHeight: 80,
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        titleSpacing: 16.0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentOrange))
          : RefreshIndicator(
        onRefresh: _loadProfileData, // Оновлення даних потягуванням
        color: accentOrange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Привітання
                _buildWelcomeMessage(theme),
                const SizedBox(height: 24),

                // 2. AI Асистент
                _buildAIAssistant(context, theme),
                const SizedBox(height: 8),

                // 2. Головна кнопка дії (Запис до лікаря)
                _buildBookAction(context, theme),
                const SizedBox(height: 30),

                // 3. 🚀 НОВИЙ ВІДЖЕТ: Список майбутніх візитів
                _buildMyAppointments(context, theme),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Віджети Екрану ---

  /// Привітання користувача
  Widget _buildWelcomeMessage(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Вітаємо,',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.w300,
          ),
        ),
        Text(
          _userName ?? 'Пацієнт', // Використовуємо завантажене ім'я
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAIAssistant(BuildContext context, ThemeData theme) {
    return _buildMainActionButton(
      context: context,
      title: 'AI Assistant',
      subtitle: 'Ask an AI Assistant',
      icon: Icons.smart_toy,
      color: theme.colorScheme.primary, // Teal
      onTap: () {
        // Перехід на екран AI асистента
        Navigator.pushNamed(context, '/ai_assistant');
      },
    );

  }

  /// Головна кнопка: Запис на прийом
  Widget _buildBookAction(BuildContext context, ThemeData theme) {
    return _buildMainActionButton(
      context: context,
      title: 'Записатись на прийом',
      subtitle: 'Знайти лікаря та обрати час',
      icon: Icons.calendar_month_outlined,
      color: theme.colorScheme.primary, // Teal
      onTap: () {
        // Перехід на екран бронювання
        Navigator.pushNamed(context, '/book_appointment');
      },
    );
  }

  /// 🚀 4. НОВИЙ ВІДЖET ЗІ STREAMBUILDER
  /// Показує список майбутніх візитів пацієнта
  Widget _buildMyAppointments(BuildContext context, ThemeData theme) {
    final String currentUserId = _auth.currentUser!.uid;
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Мої візити',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // StreamBuilder автоматично слухає зміни в 'appointments'
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('appointments')
              .where('patientId', isEqualTo: currentUserId) // 👈 Фільтр для пацієнта
              .where('date', isGreaterThanOrEqualTo: todayDate) // Тільки майбутні
              .orderBy('date')
              .orderBy('slot')
              .snapshots(),
          builder: (context, snapshot) {
            // Стан завантаження
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Якщо помилка
            if (snapshot.hasError) {
              return Center(child: Text('Помилка завантаження: ${snapshot.error}'));
            }
            // Якщо немає даних
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildNoAppointmentsCard(context); // Картка "Немає записів"
            }

            // Якщо дані є, будуємо список
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildAppointmentCard(
                    context: context,
                    doctorName: data['doctorName'] ?? 'Лікар',
                    date: data['date'] ?? '??-??',
                    time: data['slot'] ?? '??:??',
                    status: data['status'] ?? 'pending',
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// 🚀 Картка для одного візиту (для пацієнта)
  Widget _buildAppointmentCard({
    required BuildContext context,
    required String doctorName,
    required String date,
    required String time,
    required String status,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // Форматуємо дату для кращого вигляду
    String formattedDate = '';
    try {
      formattedDate = DateFormat('d MMMM, yyyy').format(DateTime.parse(date));
    } catch (e) {
      formattedDate = date;
    }

    // Визначаємо колір та іконку для статусу
    IconData statusIcon = Icons.pending_outlined;
    Color statusColor = Colors.orange;
    if (status == 'confirmed') {
      statusIcon = Icons.check_circle_outline;
      statusColor = Colors.green;
    } else if (status == 'cancelled') {
      statusIcon = Icons.cancel_outlined;
      statusColor = Colors.red;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Іконка статусу
            CircleAvatar(
              radius: 24,
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(statusIcon, color: statusColor, size: 28),
            ),
            const SizedBox(width: 16),
            // Інформація про візит
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctorName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$formattedDate о $time',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            // TODO: Додати кнопку 'Скасувати'
          ],
        ),
      ),
    );
  }

  /// Картка "Немає записів"
  Widget _buildNoAppointmentsCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, color: Colors.grey.shade500),
            const SizedBox(width: 12),
            Text(
              'У вас немає майбутніх візитів',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  /// Базовий віджет для кнопок-карток
  Widget _buildMainActionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  /// 🚀 Навігація до профілю пацієнта
  Future<void> _navigateToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HealthProfileScreen()), // Веде на профіль пацієнта
    );
    // Оновлюємо дані (аватар/ім'я) після повернення
    _loadProfileData();
  }

  /// Хедер з аватаром
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = theme.colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: _navigateToProfile, // Веде на профіль пацієнта
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _avatarUrl != null && _avatarUrl!.startsWith('assets/')
                ? AssetImage(_avatarUrl!)
                : null,
            child: _avatarUrl == null || !_avatarUrl!.startsWith('assets/')
                ? Icon(Icons.person, color: primaryTeal, size: 30) // Іконка пацієнта
                : null,
          ),
        ),
      ],
    );
  }
}