import 'package:flutter/material.dart';
import '../models/conversation.dart';

class ConversationList extends StatelessWidget {
  final List<Conversation> conversations;
  final String? selectedId;
  final Function(String) onSelect;
  final Function(String) onDelete;

  const ConversationList({
    Key? key,
    required this.conversations,
    required this.selectedId,
    required this.onSelect,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return Center(
        child: Text(
          'لا توجد محادثات',
          style: TextStyle(
            color: Colors.grey.withOpacity(0.6),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final isSelected = conversation.id == selectedId;

        return ListTile(
          title: Text(
            conversation.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          selected: isSelected,
          selectedTileColor: Colors.grey.withOpacity(0.2),
          onTap: () => onSelect(conversation.id),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => onDelete(conversation.id),
                child: const Text(
                  'حذف',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
