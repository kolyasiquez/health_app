import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель пацієнта'),
      ),
      drawer: const AppDrawer(userType: 'patient'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ласкаво просимо, Іване!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 30),
            _buildFeatureCard(
              context,
              icon: Icons.personal_injury,
              title: 'Мій медичний профіль',
              subtitle: 'Перегляд та оновлення даних',
              onTap: () {
                Navigator.pushNamed(context, '/health_profile');
              },
            ),
            _buildFeatureCard(
              context,
              icon: Icons.calendar_today,
              title: 'Мої записи на прийом',
              subtitle: 'Запланувати або переглянути',
              onTap: () {
                Navigator.pushNamed(context, '/appointments');
              },
            ),
            _buildFeatureCard(
              context,
              icon: Icons.auto_awesome,
              title: 'AI Асистент',
              subtitle: 'Отримайте швидкі відповіді на питання',
              onTap: () {
                Navigator.pushNamed(context, '/ai_assistant');
              },
            ),
            _buildFeatureCard(
              context,
              icon: Icons.notifications,
              title: 'Messages',
              subtitle: 'Сповіщення та нагадування',
              onTap: () {
                // Навігація до екрану повідомлень
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 30, color: Colors.deepPurpleAccent),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}