// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// 🚀 1. ДОДАНО ІМПОРТИ ДЛЯ ЛОКАЛІЗАЦІЇ
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

// Імпорти ваших екранів
import 'screens/auth/login_screen.dart';
import 'screens/patient/patient_dashboard_screen.dart';
import 'screens/doctor/doctor_dashboard_screen.dart';
import 'screens/patient/health_profile_screen.dart';
import 'screens/appointment/appointment_list_screen.dart';
import 'screens/ai_assistant/ai_assistant_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/auth/pending_verification_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

// 🚀 2. ДОДАНО ІМПОРТ НОВОГО ЕКРАНУ
// (Перевірте, чи правильний ваш шлях)
import 'screens/patient/book_appointment_screen.dart';

// import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🚀 3. ДОДАНО ІНІЦІАЛІЗАЦІЮ ЛОКАЛІ (ДЛЯ АНГЛІЙСЬКОЇ)
  // Це виправляє помилку LocaleDataException
  await initializeDateFormatting('en_US', null);

  runApp(const HealthApp());
}

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  // Ваші кольори (без змін)
  static const Color primaryTeal = Color(0xFF008080);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color lightBackground = Color(0xFFF0F2F5);
  static const Color darkText = Color(0xFF333333);
  static const Color greyText = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health App',
      debugShowCheckedModeBanner: false,

      // Ваша тема (без змін)
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryTeal,
        colorScheme: const ColorScheme.light(
          primary: primaryTeal,
          secondary: accentOrange,
          background: lightBackground,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: darkText,
          onSurface: darkText,
        ),
        scaffoldBackgroundColor: lightBackground,
        cardColor: Colors.white,
        hintColor: const Color(0xFF999999),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(color: darkText, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: darkText, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: darkText),
          bodyMedium: TextStyle(color: greyText),
          bodySmall: TextStyle(color: Color(0xFF999999)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            minimumSize: const Size.fromHeight(60),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryTeal,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            borderSide: BorderSide(color: primaryTeal, width: 2.0),
          ),
          labelStyle: const TextStyle(color: greyText),
          hintStyle: const TextStyle(color: Color(0xFF999999)),
          prefixIconColor: primaryTeal,
        ),
      ),

      // 🚀 4. ДОДАНО НАЛАШТУВАННЯ ЛОКАЛІЗАЦІЇ
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // Англійська
        Locale('uk', 'UA'), // Українська (можна залишити)
      ],
      locale: const Locale('en', 'US'), // Встановлюємо англійську
      // --- Кінець налаштувань локалізації ---

      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/patient_dashboard': (context) => const PatientDashboardScreen(),
        '/doctor_dashboard': (context) => const DoctorDashboardScreen(),
        '/health_profile': (context) => const HealthProfileScreen(),
        '/appointments': (context) => const AppointmentListScreen(),
        '/ai_assistant': (context) => const AIAssistantScreen(),
        '/pending_verification': (context) => const PendingVerificationScreen(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),

        // 🚀 5. ДОДАНО НОВИЙ МАРШРУТ
        '/book_appointment': (context) => const BookAppointmentScreen(),
      },
    );
  }
}