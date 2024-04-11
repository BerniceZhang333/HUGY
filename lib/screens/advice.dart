import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hugy/api/nlp.dart';
import 'package:hugy/models/task.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  @override
  void initState() {
    super.initState();
    getActivity();
  }

  List<String> activities = [];

  Future<void> getActivity() async {
    String key = await FirebaseFirestore.instance
        .collection("keys")
        .doc('openai_key')
        .get()
        .then((value) => value.data()?['data']);
    final gemini = GenerativeModel(model: "gemini-pro", apiKey: key);

    FirebaseFirestore fs = FirebaseFirestore.instance;
    String userId = FirebaseAuth.instance.currentUser!.uid;
    var collection = fs.collection("users").doc(userId).collection("entries");

    // get last entry
    var snapshot = await collection
        .orderBy("timeCreated", descending: true)
        .limit(1)
        .get();
    //String? mood = await getMood(snapshot.docs.first.data()['content']);
    String lastEntry = snapshot.docs.first.data()['content'];

    String systemPrompt =
        'act as a mental health expert. Provide a list of activities that can help me improve my mood. ';
    String userPrompt =
        "Please provide 10 activities that can help me improve my mood.In json format. Exactly like this: {\"activities\": ['activity1', 'activity2']} etc.";

    final chat = gemini.startChat(history: [
      Content.text(userPrompt),
      Content.model([TextPart(systemPrompt)]),
    ]);

    var response = await chat.sendMessage(Content.text(userPrompt));

    print(response.text);
    setState(() {
      Map<String, dynamic> activities = jsonDecode(response.text!);
      activities['activities'].forEach((activity) {
        this.activities.add(activity);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Future<void> addToTasks(Task task) async {
      final user = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid);

      final querySnapshot = await user
          .collection('tasks')
          .where('title', isEqualTo: task.title)
          .get();
      if (querySnapshot.docs.isEmpty) {
        await user.collection('tasks').add(task.toJson());
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Recommendations"),
      ),
      body: Container(
        child: ListView.builder(
            itemCount: activities.length,
            itemBuilder: (BuildContext context, int index) {
              return Card(
                child: ListTile(
                  onTap: () async {
                    Task task = Task(
                      title: activities[index],
                      completed: false,
                    );
                    await addToTasks(task);

                    activities.removeAt(index);
                    setState(() {});

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Task added to your list."),
                      ),
                    );
                  },
                  contentPadding: const EdgeInsets.all(10),
                  title: Text(activities[index]),
                ),
              );
            }),
      ),
    );
  }
}

class CheckBackLater extends StatelessWidget {
  const CheckBackLater({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Check back later if recommendations don't load."),
    );
  }
}
