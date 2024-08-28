import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugy/chat/chat.dart';
import 'package:hugy/screens/chat.dart';
import 'package:uuid/uuid.dart';

List<Map<String, dynamic>> chatBots = [
  {
    "name": "June",
    "description": "Mental Health Expert",
    "behavior":
        "You are a mental health expert named June. You will give advice and useful information to users."
  },
  {
    "name": "Domino",
    "description": "Riddler",
    "behavior":
        "You are a playful bot named Domino. You will ask riddles to users."
  },
  {
    "name": "May",
    "description": "Humurous and helpful bot",
    "behavior":
        " You are a humurous bot named May. They can offer lighthearted conversations and suggestions to help users relax in a fun atmosphere."
  },
  {
    "name": "April",
    "description": "Philosopher",
    "behavior":
        "You are a philosopher named April, help users (analyze and evaluate different perspectives and values of life), as well as guide users to (deepen their thinking) about the meaning and value of life through (philosophical exercises and reflections)."
  }
];

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Stream<QuerySnapshot> loadChats() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('chats')
        .where('owner', isEqualTo: userId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Contacts"),
        actions: [
          IconButton(
            onPressed: () {
              TextEditingController botNameController = TextEditingController();
              // display dialog to add new bot
              /* showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                        title: Text("Add New Bot"),
                        content: TextField(
                          controller: _botNameController,
                          decoration: InputDecoration(
                            labelText: "Bot Name",
                          ),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () async {
                                final user_id =
                                    FirebaseAuth.instance.currentUser!.uid;
                                Chat chat = Chat(
                                    chatName: _botNameController.text,
                                    id: (user_id.hashCode +
                                            Random().nextInt(100))
                                        .toString(),
                                    messages: [],
                                    owner: user_id);
                                await ChatService().createNewChat(chat);
                                Navigator.of(context).pop();
                              },
                              child: Text("Add")),
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text("Cancel")),
                        ],
                      )); */
              showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return ListView.builder(
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(chatBots[index]["name"]),
                          subtitle: Text(chatBots[index]["description"]),
                          onTap: () async {
                            final userId =
                                FirebaseAuth.instance.currentUser!.uid;
                            Chat chat = Chat(
                                chatName: chatBots[index]["name"],
                                id: const Uuid().v4(),
                                messages: [],
                                owner: userId,
                                behavior: chatBots[index]["behavior"]);
                            await ChatService().createNewChat(chat);
                            if (!mounted) return;
                            Navigator.of(context).pop();
                          },
                        );
                      },
                      itemCount: chatBots.length,
                    );
                  });
            },
            icon: const Icon(Icons.person_add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Search',
                  prefixIcon: Icon(Icons.search)),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
              stream: loadChats(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No chats found.'));
                }

                final chatDocs = snapshot.data!.docs;
                final filteredChats = chatDocs.where((doc) {
                  final chatName = doc['chatName'].toString().toLowerCase();
                  return chatName.contains(_searchQuery);
                }).toList();

                return Expanded(
                  child: ListView.builder(
                    itemCount: filteredChats.length,
                    itemBuilder: (ctx, index) {
                      final chatDoc = filteredChats[index];
                      return Dismissible(
                        confirmDismiss: (direction) {
                          return showDialog(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog(
                                title: const Text('Are you sure?'),
                                content: const Text(
                                    'Do you want to delete this chat?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop(false);
                                    },
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await ChatService()
                                          .deleteChat(chatDocs[index]['id']);

                                      if (!mounted) return;
                                      Navigator.of(ctx).pop(true);
                                    },
                                    child: const Text('Yes'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        direction: DismissDirection.endToStart,
                        key: ValueKey(chatDoc['id']),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (BuildContext ctx) {
                              return ChatPage(
                                chatId: chatDoc['id'],
                                botName: chatDoc['chatName'],
                                behavior: chatDoc['behavior'],
                              );
                            }));
                          },
                          title: Text(chatDoc['chatName']),
                        ),
                      );
                    },
                  ),
                );
              })
        ],
      ),
    );
  }
}
