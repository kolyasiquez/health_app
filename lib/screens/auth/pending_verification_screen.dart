// lib/screens/auth/pending_verification_screen.dart

import 'package:flutter/material.dart';
import 'package:health_app/screens/auth/auth_service.dart';

class PendingVerificationScreen extends StatelessWidget {
  const PendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification pending'),
        actions: [
          // Кнопка виходу
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Exit',
            onPressed: () async {
              await AuthService().signOut();
              // Повертаємо користувача на екран входу
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                      (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timelapse,
                size: 100,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 30),
              Text(
                'Your application is under review',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                'An administrator will review your information. This usually takes up to 24 hours.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Text(
                'You can safely close the app. Once your account is approved, you will be automatically redirected the next time you log in.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}