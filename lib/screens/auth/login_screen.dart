import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Оголошення контролерів для полів вводу
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // Звільнення контролерів, коли віджет видаляється
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF121212), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, size: 100, color: Colors.deepPurpleAccent),
                const SizedBox(height: 20),
                Text(
                  'Мобільний медичний помічник',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Поле для електронної пошти
                TextField(
                  controller: _emailController, // Прив'язка контролера
                  decoration: const InputDecoration(
                    labelText: 'Електронна пошта',
                    prefixIcon: Icon(Icons.email, color: Colors.deepPurpleAccent),
                  ),
                ),
                const SizedBox(height: 20),
                // Поле для пароля
                TextField(
                  controller: _passwordController, // Прив'язка контролера
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: Colors.deepPurpleAccent),
                  ),
                ),
                const SizedBox(height: 30),
                // Кнопка "Увійти"
                ElevatedButton(
                  onPressed: () {
                    // Отримання значень з контролерів
                    final email = _emailController.text;
                    final password = _passwordController.text;

                    // TODO: Додайте тут вашу логіку авторизації (наприклад, з Firebase Auth)
                    // Для тестування виведемо значення в консоль
                    print('Email: $email');
                    print('Password: $password');

                    Navigator.pushReplacementNamed(context, '/patient_dashboard');
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                  ),
                  child: const Text('Увійти'),
                ),
                const SizedBox(height: 10),
                // Кнопка "Зареєструватися"
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/registration');
                  },
                  child: Text(
                    'Зареєструватися',
                    style: TextStyle(color: Colors.deepPurpleAccent.shade200),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}