import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../services/webhook_service.dart';
import '../services/storage_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/conversation_list.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final uuid = const Uuid();

  List<Message> _messages = [];
  List<Conversation> _conversations = [];
  String? _currentConversationId;
  bool _isLoading = false;
  bool _sidebarOpen = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _createNewConversation();
  }

  Future<void> _loadConversations() async {
    final conversations = await StorageService.getAllConversations();
    setState(() {
      _conversations = conversations;
    });
  }

  Future<void> _createNewConversation() async {
    final conversationId = uuid.v4();
    final conversation = Conversation(
      id: conversationId,
      title: 'محادثة جديدة',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await StorageService.saveConversation(conversation);
    setState(() {
      _currentConversationId = conversationId;
      _messages = [];
      _conversations.insert(0, conversation);
    });
  }

  Future<void> _loadConversation(String conversationId) async {
    final messages = await StorageService.getMessages(conversationId);
    setState(() {
      _currentConversationId = conversationId;
      _messages = messages;
      _sidebarOpen = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty || _isSending) return;

    final message = Message(
      id: uuid.v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      conversationId: _currentConversationId!,
    );

    setState(() {
      _messages.add(message);
      _isSending = true;
      _isLoading = true;
    });

    await StorageService.saveMessage(message);
    _controller.clear();
    _scrollToBottom();

    try {
      final stream = await WebhookService.sendMessage(text, _currentConversationId!);

      String fullResponse = '';

      await stream.forEach((chunk) {
        fullResponse += chunk;
        setState(() {
          if (_messages.isNotEmpty && !_messages.last.isUser) {
            _messages.last.text = fullResponse;
          }
        });
        _scrollToBottom();
      });

      if (fullResponse.isNotEmpty) {
        final assistantMessage = Message(
          id: uuid.v4(),
          text: fullResponse,
          isUser: false,
          timestamp: DateTime.now(),
          conversationId: _currentConversationId!,
        );

        await StorageService.saveMessage(assistantMessage);

        final conversation = _conversations
            .firstWhere((c) => c.id == _currentConversationId);
        final updatedConversation = Conversation(
          id: conversation.id,
          title: conversation.title == 'محادثة جديدة'
              ? text.length > 30
                  ? '${text.substring(0, 30)}...'
                  : text
              : conversation.title,
          createdAt: conversation.createdAt,
          updatedAt: DateTime.now(),
        );
        await StorageService.saveConversation(updatedConversation);
        _loadConversations();
      }
    } catch (e) {
      final errorMessage = Message(
        id: uuid.v4(),
        text: 'عذراً، حدث خطأ: $e',
        isUser: false,
        timestamp: DateTime.now(),
        conversationId: _currentConversationId!,
      );
      setState(() {
        _messages.add(errorMessage);
      });
    } finally {
      setState(() {
        _isSending = false;
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _deleteAllConversations() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح جميع المحادثات'),
        content: const Text('هل أنت متأكد؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await StorageService.deleteAllConversations();
              await _loadConversations();
              await _createNewConversation();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width > 600)
            _buildSidebar(context),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: _messages.isEmpty
                      ? _buildWelcomeScreen()
                      : _buildMessagesList(),
                ),
                _buildComposer(context),
              ],
            ),
          ),
        ],
      ),
      drawer: MediaQuery.of(context).size.width <= 600
          ? Drawer(
              child: _buildSidebar(context),
            )
          : null,
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          if (MediaQuery.of(context).size.width <= 600)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          const Text(
            'وئام',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _createNewConversation,
              icon: const Icon(Icons.add),
              label: const Text('محادثة جديدة'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'المحادثات',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: ConversationList(
              conversations: _conversations,
              selectedId: _currentConversationId,
              onSelect: _loadConversation,
              onDelete: (id) async {
                await StorageService.deleteConversation(id);
                _loadConversations();
                if (id == _currentConversationId) {
                  await _createNewConversation();
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return ElevatedButton.icon(
                      onPressed: () => themeProvider.toggleTheme(),
                      icon: Icon(
                        themeProvider.isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                      ),
                      label: Text(
                        themeProvider.isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _deleteAllConversations,
                  icon: const Icon(Icons.delete),
                  label: const Text('مسح المحادثات'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF0e9384),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Center(
                child: Text(
                  'و',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'حيّاك الله في وئام',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'مستشارك الأسري الذكي — بخصوصية تامة، وبكل ود.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSuggestionCard(
                    icon: '🌷',
                    title: 'ابدأ بالترحيب',
                    text: 'السلام عليكم، كيف الحال؟',
                    message: 'السلام عليكم، كيف الحال؟',
                  ),
                  const SizedBox(height: 12),
                  _buildSuggestionCard(
                    icon: '🏠',
                    title: 'خلاف زوجي',
                    text: 'خلاف مستمر حول مصاريف البيت',
                    message:
                        'عندي خلاف مستمر مع زوجتي حول مصاريف البيت، كيف نتفاهم؟',
                  ),
                  const SizedBox(height: 12),
                  _buildSuggestionCard(
                    icon: '👨‍👦',
                    title: 'تربية الأبناء',
                    text: 'التعامل مع عناد المراهقين',
                    message:
                        'ابني المراهق صار عنيد ولا يسمع الكلام، كيف أتعامل معه؟',
                  ),
                  const SizedBox(height: 12),
                  _buildSuggestionCard(
                    icon: '⚖️',
                    title: 'استشارة قانونية',
                    text: 'حقوق الزوجة في القانون الإماراتي',
                    message:
                        'ما هي حقوق الزوجة في قانون الأحوال الشخصية الإماراتي؟',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard({
    required String icon,
    required String title,
    required String text,
    required String message,
  }) {
    return GestureDetector(
      onTap: () => _sendMessage(message),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.withOpacity(0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0e9384),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        }
        return MessageBubble(message: _messages[index]);
      },
    );
  }

  Widget _buildComposer(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 8,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالتك إلى وئام...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  enabled: !_isSending,
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                onPressed: _isSending
                    ? null
                    : () => _sendMessage(_controller.text),
                child: Icon(
                  _isSending ? Icons.pause : Icons.arrow_upward,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'وئام مساعد ذكي وقد يخطئ أحياناً — وفي حالات الخطر اتصل فوراً بالشرطة 999.',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
