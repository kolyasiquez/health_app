import 'package:flutter/material.dart';

class AppointmentListScreen extends StatelessWidget {
  const AppointmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мої записи на прийом'),
      ),
      body: const Center(
        child: Text('Це сторінка зі списком записів.'),
      ),
    );
  }
}