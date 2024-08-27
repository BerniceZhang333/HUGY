import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:hugy/auth/gpt.dart';
import 'package:hugy/chat/chat.dart';
import 'package:hugy/chat/message.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  const ChatPage({Key? key, required this.chatId}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final gemini = Gemini.instance;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isMe ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: MarkdownBody(
          data: message.content,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(color: message.isMe ? Colors.black87 : Colors.black),
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
      final message = Message(
        content: messageText,
        isMe: true,
        timeSent: DateTime.now(),
      );

      await ChatService().addMessage(widget.chatId, message);
      _messageController.clear();

      final behavior = await getBehavior(widget.chatId);
      final response = await gemini.text(behavior + messageText);

      if (response?.output != null) {
        final botMessage = Message(
          content: response!.output!,
          isMe: false,
          timeSent: DateTime.now(),
        );
        await ChatService().addMessage(widget.chatId, botMessage);
      }
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
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final chat = Chat.fromDocumentSnapshot(snapshot.data!);
              return Text(chat.chatName);
            }
            return const Text('Loading...');
          },
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final chat = Chat.fromDocumentSnapshot(snapshot.data!);
                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    itemCount: chat.messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(
                          chat.messages[chat.messages.length - 1 - index]);
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          _buildInputArea(),
        ],
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
              onSubmitted: (_) => _sendMessage(),
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
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}
