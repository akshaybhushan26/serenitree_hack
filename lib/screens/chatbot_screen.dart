import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

class ChatbotScreen extends StatefulWidget {
  final String? medicationName;

  const ChatbotScreen({super.key, this.medicationName});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  final _aiService = AIService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    if (widget.medicationName != null) {
      _addBotMessage('Hello! I can help you with information about ${widget.medicationName}. What would you like to know?');
    } else {
      _addBotMessage('Hello! I\'m your medication assistant. How can I help you today?');
    }
  }

  Future<void> _loadChatHistory() async {
    final history = await _storageService.getChatHistory();
    setState(() {
      _messages.addAll(history);
    });
  }

  void _addBotMessage(String message) {
    final botMessage = {
      'isUser': false,
      'message': message,
      'timestamp': DateTime.now(),
    };
    setState(() {
      _messages.add(botMessage);
    });
    _storageService.saveChatMessage(botMessage);
  }

  void _addUserMessage(String message) {
    final userMessage = {
      'isUser': true,
      'message': message,
      'timestamp': DateTime.now(),
    };
    setState(() {
      _messages.add(userMessage);
    });
    _storageService.saveChatMessage(userMessage);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleUserMessage(String message) async {
    if (message.trim().isEmpty) return;

    _addUserMessage(message);
    _messageController.clear();
    setState(() => _isLoading = true);

    try {
      final medications = await _aiService.analyzePrescription(message);
      if (medications.isNotEmpty) {
        final response = 'I found information about the following medications:\n\n' +
            medications.map((med) => 
              '${med["name"]}:\n' +
              '- Dosage: ${med["dosage"]}\n' +
              '- Frequency: ${med["frequency"]}\n' +
              (med["time"]?.isNotEmpty == true ? '- Time: ${med["time"]}\n' : '')
            ).join('\n');
        _addBotMessage(response);
      } else {
        final response = await _aiService.chat(message);
        _addBotMessage(response);
      }
    } catch (e) {
      _addBotMessage('I\'m sorry, I encountered an error while processing your request. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Assistant'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return _MessageBubble(
                  message: message['message'] as String,
                  isUser: message['isUser'] as bool,
                ).animate().fade().slideY(
                      begin: 0.2,
                      end: 0,
                      duration: const Duration(milliseconds: 300),
                    );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ask about your medications...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: _handleUserMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _handleUserMessage(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const _MessageBubble({
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isUser
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}