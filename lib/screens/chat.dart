import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String botName;
  final String behavior;
  const ChatPage(
      {Key? key,
      required this.chatId,
      required this.botName,
      required this.behavior})
      : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final gemini = Gemini.instance;

  List<Content> _conversation = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversation();
    });
  }

  String convertConversationToJson() {
    var c = {};
    c['messages'] = _conversation.map((content) => content.toJson()).toList();
    return c.toString();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        if (mounted) {
          setState(() {
            _conversation = (data['messages'] as List)
                .map((message) => Content.fromJson(message))
                .toList();
          });
        }
      } else {
        // Start a new conversation
        final response = await gemini.chat(_conversation);
        if (response?.output != null) {
          final botMessage = Content(
            parts: [Parts(text: response!.output!)],
            role: 'model',
          );
          if (mounted) {
            setState(() {
              _conversation.add(botMessage);
            });
          }
          await _saveConversation();
        }
      }
    } catch (e) {
      print('Error loading conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading conversation: ${e.toString()}')),
        );
      }
    }
    if (mounted) _scrollToBottom();
  }

  List<Map<String, dynamic>> _serializeConversation(
      List<Content> conversation) {
    return conversation.map((content) {
      return {
        'role': content.role,
        'parts': content.parts?.map((part) {
          return {'text': part.text}; // Assuming `text` is the relevant field
        }).toList(),
      };
    }).toList();
  }

  Future<void> _saveConversation() async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'messages': _serializeConversation(_conversation),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving conversation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving conversation: ${e.toString()}')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessageBubble(Content message) {
    final isUserMessage = message.role == 'user';
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUserMessage ? Colors.blue[700] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: MarkdownBody(
          data: message.parts?.first.text ?? '',
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: isUserMessage ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final userMessage = Content(
        parts: [
          Parts(text: messageText),
        ],
        role: 'user',
      );

      setState(() {
        _conversation.add(userMessage);
        _messageController.clear();
      });

      final response = await gemini.chat(_conversation);

      if (response?.output != null) {
        final botMessage = Content(
          parts: [Parts(text: response!.output!)],
          role: 'model',
        );
        setState(() {
          _conversation.add(botMessage);
        });
      }

      await _saveConversation();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.botName}'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
      ),
      body: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            Expanded(
              child: _conversation.isEmpty
                  ? Center(
                      child: Text(
                        'Get started by sending a message!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      itemCount: _conversation.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(
                            _conversation[_conversation.length - 1 - index]);
                      },
                    ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 16, color: Colors.black),
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) async => await _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: _isLoading ? null : _sendMessage,
            color: Colors.blue[700],
          ),
        ],
      ),
    );
  }
}
