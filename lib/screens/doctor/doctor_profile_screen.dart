import 'package:flutter/material.dart';

// Це просто заглушка, щоб навігація з дашборду працювала.
// Пізніше ви можете реалізувати цей екран.
class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor\'s profile'),
      ),
      body: const Center(
        child: Text('etc...'),
      ),
    );
  }
}