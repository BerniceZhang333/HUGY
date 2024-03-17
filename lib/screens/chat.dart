import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hugy/auth/gpt.dart';
import 'package:hugy/chat/chat.dart';
import 'package:hugy/chat/message.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  const ChatPage({super.key, required this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final gemini = Gemini.instance;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // get the api key

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _scrollDown();
      }
    });
    // send hello to the bot so that it can start the conversation
  }

  /*

  Future<void> getBotResponse(String message, String behavior) async {
    final botId = widget.chatId;

    //get response
    try {
      await getResponse(message, behavior, botId)
          .then((value) => {
                //add response to chat
                ChatService().addMessage(
                    botId,
                    Message(
                        content: value!, isMe: false, timeSent: DateTime.now()))
              })
          .catchError((error) => {
                ChatService().addMessage(
                    botId,
                    Message(
                        content: "Sorry, Cannot reach bot",
                        isMe: false,
                        timeSent: DateTime.now()))
              });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sorry, Cannot reach bot'),
        ),
      );
    }
  }
  */

  Widget textBubble(Message message) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Align(
        alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.blue,
          ),
          child: Container(
            child: Text(
              message.content,
              style: const TextStyle(fontSize: 20.0),
            ),
          ),
        ),
      ),
    );
  }

  void _scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _sendChatMessage(String message) async {
    setState(() {
      _loading = true;
    });

    try {
      String behavior = await getBehavior(widget.chatId);
      final response = await gemini.text(behavior + message).then((value) {
        ChatService().addMessage(
            widget.chatId,
            Message(
                content: value!.output!,
                isMe: false,
                timeSent: DateTime.now()));
      }).whenComplete(() {
        _scrollDown();
      });
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _messageController.clear();
      _scrollDown();
      setState(() {
        _loading = false;
      });
      _textFieldFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .get()
            .asStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Chat c = Chat.fromDocumentSnapshot(snapshot.data!);
            return Scaffold(
              appBar: AppBar(
                title: Text(c.chatName),
                centerTitle: true,
              ),
              body: Container(
                color: Colors.grey[200],
                child: Column(children: [
                  Expanded(
                    child: ListView.builder(
                        reverse: true,
                        controller: _scrollController,
                        itemCount: c.messages.length,
                        itemBuilder: ((context, index) {
                          return textBubble(
                              c.messages[c.messages.length - 1 - index]);
                        })),
                  ),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            focusNode: _textFieldFocus,
                            controller: _messageController,
                            onSubmitted: (value) async {
                              String behavior = await getBehavior(
                                  widget.chatId); // get behavior
                              Message message = Message(
                                content: value,
                                isMe: true,
                                timeSent: DateTime.now(),
                              );
                              await ChatService()
                                  .addMessage(widget.chatId, message);

                              await _sendChatMessage(value);

                              // setState
                              setState(() {
                                _messageController.clear();
                              }); // we will use streams later
                            },
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (_messageController.text.isEmpty) {
                              return;
                            }
                            String behavior = await getBehavior(widget.chatId);
                            Message message = Message(
                              content: _messageController.text,
                              isMe: true,
                              timeSent: DateTime.now(),
                            );
                            await ChatService()
                                .addMessage(widget.chatId, message);
                            await _sendChatMessage(_messageController.text);
                            setState(() {
                              _messageController.clear();
                            });
                          },
                          icon: const Icon(Icons.send),
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            );
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}
