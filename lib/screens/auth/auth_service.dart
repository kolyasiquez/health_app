import 'dart:developer';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class AuthService {
  // Налаштування API URL залежно від платформи
  final String _apiUrl = Platform.isAndroid ? "http://10.0.2.2:3000" : "http://localhost:3000";

  Future<Map<String, dynamic>?> registerUserWithEmailAndPassword(String name, String email, String password) async {
    try {
      log("Sending registration request to: $_apiUrl/api/auth/register");

      final response = await http.post(
        Uri.parse('$_apiUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      log("Received response with status code: ${response.statusCode}");

      if (response.statusCode == 201) {
        log("Registration successful");
        return jsonDecode(response.body);
      } else {
        log("Registration failed with status code: ${response.statusCode}");
        log("Server response body: ${response.body}");
        return null;
      }
    } catch (e) {
      log("Error during registration request: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> loginUserWithEmailAndPassword(String email, String password) async {
    try {
      log("Sending login request to: $_apiUrl/api/auth/login");

      final response = await http.post(
        Uri.parse('$_apiUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      log("Received response with status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        log("Login successful");
        return jsonDecode(response.body);
      } else {
        log("Login failed with status code: ${response.statusCode}");
        log("Server response body: ${response.body}");
        return null;
      }
    } catch (e) {
      log("Error during login request: $e");
      return null;
    }
  }

  // Метод для виходу
  Future<void> signOut() async {
    log("User signed out");
    // Тут можна додати логіку для видалення збережених токенів або даних користувача
  }
}
