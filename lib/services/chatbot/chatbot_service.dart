import 'dart:convert';

import '../api_config.dart';

/// One saved chat bubble from the backend.
typedef ChatbotMessage = ({bool isUser, String message, DateTime? createdAt});

class ChatbotService {
  ChatbotService._();

  /// Sends the user's message and returns the bot's reply. The backend
  /// picks the reply from chatbot_rule and saves both messages.
  static Future<ChatbotMessage> sendMessage(String message) async {
    final body = await _post('send_message.php', {'message': message});
    return _parse(body['reply'] as Map<String, dynamic>);
  }

  /// The user's saved chat, oldest first.
  static Future<List<ChatbotMessage>> getHistory() async {
    final body = await _post('get_history.php', const {});
    return (body['messages'] as List)
        .map((row) => _parse(row as Map<String, dynamic>))
        .toList();
  }

  /// Deletes the user's whole conversation on the server.
  static Future<void> clearHistory() async {
    await _post('clear_history.php', const {});
  }

  static ChatbotMessage _parse(Map<String, dynamic> row) {
    return (
      isUser: row['sender'] == 'user',
      message: row['message'] as String? ?? '',
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? ''),
    );
  }

  static Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/chatbot/$endpoint');
    final response = await ApiConfig.post(uri, body: jsonEncode(body));

    final Map<String, dynamic> decoded = jsonDecode(response.body);
    if (response.statusCode != 200 || decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Request failed.');
    }
    return decoded;
  }
}
