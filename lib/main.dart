import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/patient/patient_dashboard_screen.dart';
import 'screens/doctor/doctor_dashboard_screen.dart';
import 'screens/ai_assistant/ai_assistant_screen.dart';
import 'screens/patient/health_profile_screen.dart';
import 'screens/appointment/appointment_list_screen.dart';

void main() {
  runApp(const HealthApp());
}

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          color: Colors.blueAccent,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/patient_dashboard': (context) => const PatientDashboardScreen(),
        '/doctor_dashboard': (context) => const DoctorDashboardScreen(),
        '/health_profile': (context) => const HealthProfileScreen(),
        '/appointments': (context) => const AppointmentListScreen(),
        '/ai_assistant': (context) => const AIAssistantScreen(),
      },
    );
  }
}