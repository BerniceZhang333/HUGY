import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hugy/models/task.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  List<String> activities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getActivities();
  }

  Future<void> _getActivities() async {
    try {
      String key = await FirebaseFirestore.instance
          .collection("keys")
          .doc('openai_key')
          .get()
          .then((value) => value.data()?['data']);

      if (key == null || key.isEmpty) {
        throw Exception('API key not found');
      }

      final gemini = GenerativeModel(model: "gemini-pro", apiKey: key);

      String systemPrompt =
          'Act as a mental health expert. Provide a list of activities that can help improve mood.';
      String userPrompt =
          "Please provide 10 activities that can help improve mood. Respond ONLY with a JSON object in this exact format: {\"activities\": [\"activity1\", \"activity2\", ...]}";

      final chat = gemini.startChat(history: [
        Content.text(userPrompt),
        Content.model([TextPart(systemPrompt)]),
      ]);

      var response = await chat.sendMessage(Content.text(userPrompt));

      if (response.text != null) {
        Map<String, dynamic> activitiesMap = _parseJson(response.text!);
        if (mounted) {
          setState(() {
            activities = List<String>.from(activitiesMap['activities']);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('No response from AI');
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Map<String, dynamic> _parseJson(String jsonString) {
    try {
      // Try to parse the JSON
      Map<String, dynamic> parsed = jsonDecode(jsonString);
      if (!parsed.containsKey('activities') ||
          !(parsed['activities'] is List)) {
        throw FormatException('Invalid JSON structure');
      }
      return parsed;
    } catch (e) {
      // If parsing fails, try to extract a JSON-like structure
      RegExp regex = RegExp(r'\{[\s\S]*\}');
      Match? match = regex.firstMatch(jsonString);
      if (match != null) {
        try {
          Map<String, dynamic> extracted = jsonDecode(match.group(0)!);
          if (extracted.containsKey('activities') &&
              extracted['activities'] is List) {
            return extracted;
          }
        } catch (_) {
          // If extraction fails, fall through to the default activities
        }
      }
      // Return a default set of activities if all else fails
      return {
        'activities': [
          'Take a walk in nature',
          'Practice deep breathing exercises',
          'Call a friend or family member',
          'Write in a gratitude journal',
          'Try a new hobby or craft',
        ]
      };
    }
  }

  void _handleError(dynamic error) {
    if (mounted) {
      setState(() {
        _error = 'Unable to load recommendations. Please try again later.';
        _isLoading = false;
      });
    }
    print('Error in _getActivities: $error'); // Log for debugging
  }

  Future<void> _addToTasks(Task task) async {
    try {
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
    } catch (e) {
      print('Error adding task: $e'); // Log for debugging
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to add task. Please try again."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Recommendations"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _getActivities();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : activities.isEmpty
                  ? const CheckBackLater()
                  : ListView.builder(
                      itemCount: activities.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          child: ListTile(
                            onTap: () async {
                              Task task = Task(
                                title: activities[index],
                                completed: false,
                              );
                              await _addToTasks(task);

                              if (mounted) {
                                setState(() {
                                  activities.removeAt(index);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Task added to your list."),
                                  ),
                                );
                              }
                            },
                            contentPadding: const EdgeInsets.all(10),
                            title: Text(activities[index]),
                          ),
                        );
                      },
                    ),
    );
  }
}

class CheckBackLater extends StatelessWidget {
  const CheckBackLater({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
          "No recommendations available at the moment. Please check back later."),
    );
  }
}
