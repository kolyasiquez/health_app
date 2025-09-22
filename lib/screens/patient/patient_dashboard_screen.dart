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
          children: [
            _buildFeatureCard(
              icon: Icons.personal_injury,
              title: 'Мій медичний профіль',
              onTap: () {
                Navigator.pushNamed(context, '/health_profile');
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.calendar_today,
              title: 'Мої записи на прийом',
              onTap: () {
                Navigator.pushNamed(context, '/appointments');
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.auto_awesome,
              title: 'AI Асистент',
              onTap: () {
                Navigator.pushNamed(context, '/ai_assistant');
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.notifications,
              title: 'Повідомлення',
              onTap: () {
                // Навігація до екрану повідомлень
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.blueAccent),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}