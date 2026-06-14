import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class WebhookService {
  static const String webhookUrl = 'https://aiautomation.sanayadtech.com/webhook/112235db-e1fc-414f-980a-71184dd6be82';

  static Future<Stream<String>> sendMessage(String message, String sessionId) async {
    final controller = StreamController<String>();

    try {
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'sessionId': sessionId,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timeout after 30 seconds');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final reply = _extractReply(data);

        if (reply.isNotEmpty) {
          for (int i = 0; i < reply.length; i++) {
            await Future.delayed(const Duration(milliseconds: 20));
            controller.add(reply[i]);
          }
        }

        controller.close();
      } else {
        controller.addError('Error: ${response.statusCode}');
        controller.close();
      }
    } on TimeoutException {
      controller.addError('الاتصال استغرق وقتاً طويلاً. يرجى المحاولة مرة أخرى.');
      controller.close();
    } catch (e) {
      controller.addError('خطأ: $e');
      controller.close();
    }

    return controller.stream;
  }

  static String _extractReply(dynamic data) {
    if (data is Map) {
      if (data.containsKey('output')) return data['output'].toString();
      if (data.containsKey('text')) return data['text'].toString();
      if (data.containsKey('message')) return data['message'].toString();
      if (data.containsKey('reply')) return data['reply'].toString();

      return jsonEncode(data);
    }
    return data.toString();
  }
}
