import 'package:flutter/material.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель лікаря'),
      ),
      body: const Center(
        child: Text('Це головна сторінка для лікаря.'),
      ),
    );
  }
}