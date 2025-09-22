import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String userType;

  const AppDrawer({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blueAccent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blueAccent),
                ),
                SizedBox(height: 10),
                Text(
                  'Ім\'я Користувача', // Замініть на ім'я з моделі
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
          if (userType == 'patient') ...[
            ListTile(
              leading: const Icon(Icons.personal_injury),
              title: const Text('Мій медичний профіль'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/health_profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Мої записи'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/appointments');
              },
            ),
          ] else if (userType == 'doctor') ...[
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Графік прийомів'),
              onTap: () {
                Navigator.pop(context);
                // Навігація для доктора
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('AI Асистент'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/ai_assistant');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Вийти'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }
}