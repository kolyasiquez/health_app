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
        title: const Text('Очікування верифікації'),
        actions: [
          // Кнопка виходу
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Вийти',
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
                'Ваша заявка на розгляді',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                'Адміністратор перевірить вашу інформацію. Зазвичай це займає до 24 годин.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Text(
                'Ви можете закрити додаток. Коли ви увійдете наступного разу, вас буде автоматично перенаправлено, щойно ваш акаунт схвалять.',
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