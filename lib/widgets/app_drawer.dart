import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String userType;

  const AppDrawer({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E1E), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.deepPurpleAccent),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ім\'я Користувача',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            if (userType == 'patient') ...[
              _buildListTile(context, Icons.personal_injury, 'Мій медичний профіль', '/health_profile'),
              _buildListTile(context, Icons.calendar_today, 'Мої записи', '/appointments'),
            ] else if (userType == 'doctor') ...[
              _buildListTile(context, Icons.calendar_month, 'Графік прийомів', '/doctor_dashboard'),
            ],
            const Divider(color: Colors.white12, height: 20),
            _buildListTile(context, Icons.auto_awesome, 'AI Асистент', '/ai_assistant'),
            _buildListTile(context, Icons.logout, 'Вийти', '/'),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}