import 'package:flutter/material.dart';
// НОВЕ: Імпортуємо наш сервіс для роботи з API
import 'package:health_app/openai_service.dart'; // <-- Замініть на ваш шлях

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  _AIAssistantScreenState createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  // НОВЕ: Створюємо екземпляр нашого сервісу
  final OpenAiService _apiService = OpenAiService();

  // НОВЕ: Змінна для відстеження стану завантаження
  bool _isLoading = false;

  // НОВЕ: Метод тепер асинхронний (async)
  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final messageText = _controller.text;

    // НОВЕ: Використовуємо setState для оновлення UI
    setState(() {
      _messages.add({'sender': 'user', 'message': messageText});
      _isLoading = true; // Починаємо завантаження
    });

    _controller.clear(); // Очищуємо поле вводу

    // НОВЕ: Викликаємо API та обробляємо відповідь
    try {
      final aiResponse = await _apiService.getCompletion(messageText);
      setState(() {
        _messages.add({'sender': 'ai', 'message': aiResponse});
      });
    } catch (e) {
      // Обробляємо можливу помилку
      setState(() {
        _messages.add({'sender': 'ai', 'message': 'Виникла помилка: ${e.toString()}'});
      });
    } finally {
      // НОВЕ: Завершуємо завантаження у будь-якому випадку
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Асистент'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message['sender'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: message['sender'] == 'user' ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(message['message']!),
                  ),
                );
              },
            ),
          ),

          // НОВЕ: Показуємо індикатор завантаження, якщо _isLoading true
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Введіть ваше питання...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    // НОВЕ: Блокуємо поле вводу під час завантаження
                    readOnly: _isLoading,
                    onSubmitted: _isLoading ? null : (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  // НОВЕ: Блокуємо кнопку під час завантаження
                  onPressed: _isLoading ? null : _sendMessage,
                  color: Colors.blueAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}