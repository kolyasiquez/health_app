import 'package:flutter/material.dart';

class HealthProfileScreen extends StatelessWidget {
  const HealthProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мій медичний профіль'),
      ),
      body: const Center(
        child: Text('Це сторінка медичного профілю.'),
      ),
    );
  }
}