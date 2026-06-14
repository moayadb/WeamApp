import 'package:intl/intl.dart';

class Message {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String conversationId;
  bool isStreaming;

  Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.conversationId,
    this.isStreaming = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'conversationId': conversationId,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      conversationId: json['conversationId'] as String,
    );
  }

  String getFormattedTime() {
    return DateFormat('HH:mm').format(timestamp);
  }
}
