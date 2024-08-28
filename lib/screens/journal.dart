import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hugy/models/log.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class NoteEditor extends StatefulWidget {
  final Log? log;
  final Function(Log) onLogUpdated;

  NoteEditor({Key? key, required this.log, required this.onLogUpdated})
      : super(key: key);

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  TextEditingController logController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.log != null) {
      logController.text = widget.log!.content;
    }
    logController.addListener(_onLogChanged);
  }

  void _onLogChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _updateLog();
    });
  }

  Future<void> _updateLog() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final fs = FirebaseFirestore.instance;
    final logContent = logController.text;

    if (logContent.isEmpty) {
      return;
    }

    if (widget.log == null) {
      final newLog = Log(
        content: logContent,
        timeCreated: DateTime.now(),
        title: DateFormat('dd MMM yyyy').format(DateTime.now()),
      );
      final docRef = await fs
          .collection("users")
          .doc(userId)
          .collection("entries")
          .add(newLog.toJson());
      newLog.id = docRef.id;
      widget.onLogUpdated(newLog);
    } else {
      await fs
          .collection("users")
          .doc(userId)
          .collection("entries")
          .doc(widget.log!.id)
          .update({"content": logContent});
      final updatedLog = Log(
        id: widget.log!.id,
        content: logContent,
        timeCreated: widget.log!.timeCreated,
        title: widget.log!.title,
      );
      widget.onLogUpdated(updatedLog);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    logController.removeListener(_onLogChanged);
    logController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.log == null ? "Create a log" : "Edit log"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: logController,
          maxLines: null,
          expands: true,
          decoration: const InputDecoration(
            hintText: "Write your log here",
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}

class JournalPage extends StatefulWidget {
  const JournalPage({Key? key}) : super(key: key);

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  late PageController pageController;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  String truncate(String data) {
    return data.length > 50 ? '${data.substring(0, 50)}...' : data;
  }

  Widget noteCard(Log log) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        child: ListTile(
          title: Text(DateFormat('h:mm a').format(log.timeCreated)),
          subtitle: Text(truncate(log.content)),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await LogService().deleteLog(log.id!);
              setState(() {});
            },
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteEditor(
                  log: log,
                  onLogUpdated: (updatedLog) {
                    setState(() {});
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditor(
                log: null,
                onLogUpdated: (newLog) {
                  setState(() {});
                },
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text("Journal"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime(DateTime.now().year - 1),
                lastDate: DateTime.now(),
                initialDate: selectedDate,
              );
              if (date != null) {
                setState(() => selectedDate = date);
              }
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: LogService().getLogStreamByDate(selectedDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final logs = snapshot.data?.docs
                  .map((doc) => Log.fromDocumentSnapshot(doc))
                  .toList() ??
              [];

          return logs.isEmpty
              ? Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteEditor(
                            log: null,
                            onLogUpdated: (newLog) {
                              setState(() {});
                            },
                          ),
                        ),
                      );
                    },
                    child: const Text("Create a log"),
                  ),
                )
              : ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) => noteCard(logs[index]),
                );
        },
      ),
    );
  }
}
