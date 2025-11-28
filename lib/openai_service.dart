import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAiService {
  final String _apiKey = dotenv.env['OPENAI_API_KEY']!;
  final String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  // Історія повідомлень
  final List<Map<String, String>> _history = [];

  // НАЛАШТУВАННЯ ЛІМІТІВ
  // 1. Максимальна кількість повідомлень у пам'яті (наприклад, 5 пар запитання-відповідь + системне)
  static const int _maxHistoryCount = 11;

  // Додати системне повідомлення (воно не буде видалятися при чистці)
  void setSystemMessage(String content) {
    if (_history.isNotEmpty && _history.first['role'] == 'system') {
      _history[0] = {'role': 'system', 'content': content};
    } else {
      _history.insert(0, {'role': 'system', 'content': content});
    }
  }

  Future<String> getCompletion(String userMessage) async {
    try {
      // Додаємо повідомлення користувача
      _history.add({'role': 'user', 'content': userMessage});

      // ! ВАЖЛИВО: Перед відправкою обрізаємо історію, щоб не платити зайве
      _trimHistory();

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': _history,
          'temperature': 0.7,
          // Можна також обмежити довжину самої відповіді (в токенах)
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final aiResponse = body['choices'][0]['message']['content'];

        _history.add({'role': 'assistant', 'content': aiResponse});

        // Знову перевіряємо ліміт після відповіді
        _trimHistory();

        return aiResponse;
      } else {
        // Якщо помилка, відкочуємо останнє повідомлення користувача
        _history.removeLast();
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception('Помилка API: ${errorBody['error']['message']}');
      }
    } catch (e) {
      if (_history.isNotEmpty && _history.last['role'] == 'user') {
        _history.removeLast();
      }
      throw Exception('Помилка запиту: $e');
    }
  }

  // --- ЛОГІКА "КОВЗНОГО ВІКНА" ---
  void _trimHistory() {
    // Якщо повідомлень менше ліміту - нічого не робимо
    if (_history.length <= _maxHistoryCount) return;

    // Перевіряємо, чи є перше повідомлення системним
    bool hasSystemMessage = _history.isNotEmpty && _history.first['role'] == 'system';

    // Скільки треба видалити
    int messagesToRemove = _history.length - _maxHistoryCount;

    if (hasSystemMessage) {
      // Якщо є системне, ми його пропускаємо (індекс 0) і видаляємо старі повідомлення починаючи з індексу 1
      // Наприклад: [System, Old1, Old2, New1, New2] -> видаляємо Old1, Old2 -> лишається [System, New1, New2]
      _history.removeRange(1, 1 + messagesToRemove);
    } else {
      // Якщо системного немає, просто видаляємо найстаріші з початку
      _history.removeRange(0, messagesToRemove);
    }

    print("Історія очищена. Поточний розмір: ${_history.length}");
  }

  void clearHistory() {
    // При повному очищенні можна або видаляти все, або залишати системне
    if (_history.isNotEmpty && _history.first['role'] == 'system') {
      var sysMsg = _history.first;
      _history.clear();
      _history.add(sysMsg);
    } else {
      _history.clear();
    }
  }
}