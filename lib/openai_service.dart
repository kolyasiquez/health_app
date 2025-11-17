import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAiService {
  final String _apiKey = dotenv.env['OPENAI_API_KEY']!;
  final String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String> getCompletion(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo', // Ви можете обрати іншу модель, напр. gpt-4
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7, // Контролює "креативність"
        }),
      );

      if (response.statusCode == 200) {
        // Важливо використовувати utf8.decode для правильного відображення кирилиці
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return body['choices'][0]['message']['content'];
      } else {
        // Обробка помилок API
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception('Помилка API: ${errorBody['error']['message']}');
      }
    } catch (e) {
      // Обробка загальних помилок (напр. відсутність інтернету)
      throw Exception('Не вдалося виконати запит: $e');
    }
  }
}