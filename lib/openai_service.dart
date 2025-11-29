import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAiService {
  final String _apiKey = dotenv.env['OPENAI_API_KEY']!;
  final String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  // Історія повідомлень
  final List<Map<String, String>> _history = [];

  // Ліміт історії
  static const int _maxHistoryCount = 11;

  // 1. БАЗОВА ІНСТРУКЦІЯ (ПЕРСОНА)
  static const String _baseSystemInstruction =
      'You are a professional medical assistant in the HealthApp application. '
      'Your task is to answer the patient\'s questions, explain test results, and describe symptoms based on the provided data. '
      'IMPORTANT: You do not replace a real doctor. If the situation appears critical or life-threatening, always advise the user to call an ambulance immediately. '
      'Keep your answers concise, empathetic, and professional.';

  // Метод для встановлення або оновлення системного повідомлення
  void setSystemMessage(String content) {
    if (_history.isNotEmpty && _history.first['role'] == 'system') {
      _history[0] = {'role': 'system', 'content': content};
    } else {
      _history.insert(0, {'role': 'system', 'content': content});
    }
  }

  // 2. ОНОВЛЕНИЙ МЕТОД: Тепер приймає параметр context
  Future<String> getCompletion(String userMessage, {String? context}) async {
    try {
      // --- ЛОГІКА ОБРОБКИ КОНТЕКСТУ ---
      if (context != null && context.isNotEmpty) {
        // Якщо передали історію хвороби, додаємо її в інструкцію
        String fullSystemMessage = '$_baseSystemInstruction\n\n'
            'HERE IS THE PATIENT\'S MEDICAL HISTORY AND VISIT RESULTS:\n$context\n\n'
            'Use this information to provide personalized advice. '
            'If the user asks about their results, refer to the data above.';

        setSystemMessage(fullSystemMessage);
      } else {
        // Якщо контексту немає, переконуємося, що хоча б базова інструкція є
        if (_history.isEmpty || _history.first['role'] != 'system') {
          setSystemMessage(_baseSystemInstruction);
        }
      }
      // --------------------------------

      // Додаємо повідомлення користувача
      _history.add({'role': 'user', 'content': userMessage});

      _trimHistory();

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini', // Рекомендую нову модель (або залиште gpt-3.5-turbo)
          'messages': _history,
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final aiResponse = body['choices'][0]['message']['content'];

        _history.add({'role': 'assistant', 'content': aiResponse});
        _trimHistory();

        return aiResponse;
      } else {
        _history.removeLast();
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception('API Error: ${errorBody['error']['message']}');
      }
    } catch (e) {
      if (_history.isNotEmpty && _history.last['role'] == 'user') {
        _history.removeLast();
      }
      throw Exception('Request Failed: $e');
    }
  }

  // --- ЛОГІКА "КОВЗНОГО ВІКНА" (без змін) ---
  void _trimHistory() {
    if (_history.length <= _maxHistoryCount) return;

    bool hasSystemMessage = _history.isNotEmpty && _history.first['role'] == 'system';
    int messagesToRemove = _history.length - _maxHistoryCount;

    if (hasSystemMessage) {
      _history.removeRange(1, 1 + messagesToRemove);
    } else {
      _history.removeRange(0, messagesToRemove);
    }
  }

  void clearHistory() {
    if (_history.isNotEmpty && _history.first['role'] == 'system') {
      var sysMsg = _history.first;
      _history.clear();
      _history.add(sysMsg);
    } else {
      _history.clear();
    }
  }
}