import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/message.dart';
import '../models/conversation.dart';

class StorageService {
  static const String _conversationsKey = 'conversations';
  static const String _messagesPrefix = 'messages_';

  static Future<void> saveConversation(Conversation conversation) async {
    final prefs = await SharedPreferences.getInstance();
    final conversations = await getAllConversations();

    final index = conversations.indexWhere((c) => c.id == conversation.id);
    if (index >= 0) {
      conversations[index] = conversation;
    } else {
      conversations.add(conversation);
    }

    final json = conversations.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_conversationsKey, json);
  }

  static Future<List<Conversation>> getAllConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getStringList(_conversationsKey) ?? [];

    return json.map((e) => Conversation.fromJson(jsonDecode(e))).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Future<void> deleteConversation(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final conversations = await getAllConversations();
    conversations.removeWhere((c) => c.id == conversationId);

    final json = conversations.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_conversationsKey, json);

    await prefs.remove('$_messagesPrefix$conversationId');
  }

  static Future<void> deleteAllConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final conversations = await getAllConversations();

    for (final conv in conversations) {
      await prefs.remove('$_messagesPrefix${conv.id}');
    }

    await prefs.remove(_conversationsKey);
  }

  static Future<void> saveMessage(Message message) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_messagesPrefix${message.conversationId}';
    final messages = await getMessages(message.conversationId);

    messages.add(message);
    final json = messages.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(key, json);
  }

  static Future<List<Message>> getMessages(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_messagesPrefix$conversationId';
    final json = prefs.getStringList(key) ?? [];

    return json.map((e) => Message.fromJson(jsonDecode(e))).toList();
  }
}
