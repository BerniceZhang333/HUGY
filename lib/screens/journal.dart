import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hugy/models/log.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class NoteEditor extends StatefulWidget {
  NoteEditor({super.key, required this.log});
  Log? log;

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  TextEditingController logController = TextEditingController();
  Timer? _debounce;

  Future<void> updateLog() async {
    FirebaseFirestore fs = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await fs
        .collection("users")
        .doc(userId)
        .collection("entries")
        .doc(widget.log?.id)
        .update({
      "content": logController.text,
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.log != null) {
      logController.text = widget.log!.content;
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    if (widget.log == null) {
      if (logController.text.isNotEmpty) {
        FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection("entries")
            .add({
          "content": logController.text,
          "timeCreated": DateTime.now(),
          "title": DateFormat('dd MM yyyy').format(DateTime.now()),
        });
      }
    } else {
      updateLog();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create a log"),
      ),
      body: PopScope(
        onPopInvoked: (didPop) {
          // if the user presses the back button
        },
        child: Container(
          child: TextField(
            controller: logController,
            maxLines: 100,
            decoration: const InputDecoration(
              hintText: "Write your log here",
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ),
    );
  }
}

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  PageController pageController = PageController();

  DateTime selectedDate = DateTime(DateTime.now().year, DateTime.now().month,
      DateTime.now().day); // default to today

  String truncate(String data) {
    if (data.length > 27) {
      return data.substring(0, 27);
    } else {
      return data;
    }
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    pageController = PageController(initialPage: 0, viewportFraction: 0.8);
  }

  Widget noteCard(Log log) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: InkWell(
        onTap: () async {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => NoteEditor(
                        log: log,
                      ))).then((value) => setState(() {}));
        },
        child: Container(
            width: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              image: const DecorationImage(
                  opacity: 0.8,
                  image: AssetImage("assets/circles.png"),
                  fit: BoxFit.cover),
              boxShadow: [
                BoxShadow(
                  blurStyle: BlurStyle.outer,
                  blurRadius: 20,
                  color: Colors.black.withOpacity(0.25),
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      // time created in neat format
                      DateFormat('h:mm:a').format(log.timeCreated),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await LogService().deleteLog(log.id!);
                        setState(() {});
                      },
                    )
                  ],
                ),
                Text(truncate(log.content),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w300)),
              ],
            )),
      ),
    );
  }

  Widget carouselView(List<Log> logs, int index) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        double rotAmount = 0.0;

        rotAmount = index.toDouble() - (pageController.page ?? 0.0);
        rotAmount = (rotAmount * 0.188).clamp(-1, 1);

        return Center(
          child: Transform.rotate(
            angle: rotAmount,
            child: noteCard(logs[index % logs.length]),
          ),
        );
      },
    );
  }

// MAIN VIEW
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          backgroundColor:
              Theme.of(context).floatingActionButtonTheme.backgroundColor,
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NoteEditor(
                          log: null,
                        ))).then((value) => setState(() {}));
          },
          child: const Icon(Icons.add_outlined)),
      appBar: AppBar(
        title: const Text("Journal"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () async {
              DateTime? date = await showDatePicker(
                context: context,
                firstDate: DateTime(DateTime.now().year - 1),
                lastDate: DateTime.now(),
                initialDate: DateTime.now(),
              );

              if (date != null) {
                setState(() {
                  selectedDate = DateTime(date.year, date.month, date.day);
                });
              }
            },
          )
        ],
      ),
      body: Center(
        child: FutureBuilder<List<QueryDocumentSnapshot>>(
            future: LogService().getLogsByDate(selectedDate),
            builder: (context, snapshot) {
              return AspectRatio(
                aspectRatio: 0.8,
                child: Column(
                  children: [
                    Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            setState(() {});
                          },
                        )),
                    Text(
                      DateFormat('dd MMMM yyyy').format(selectedDate),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Container(
                          child: PageView.builder(
                        controller: pageController,
                        physics: const ClampingScrollPhysics(),
                        // PAGEVIEW STARTS HERE
                        itemBuilder: (context, index) {
                          if (snapshot.hasData &&
                              snapshot.data != null &&
                              snapshot.data?.isNotEmpty == true) {
                            List logs = snapshot.data!
                                .map((e) => Log.fromDocumentSnapshot(e))
                                .toList();
                            return carouselView(logs.cast<Log>(), index);
                          } else {
                            return SizedBox(
                              width: 200,
                              height: 200,
                              child: Column(
                                children: [
                                  const Text("No logs found"),
                                  TextButton(
                                    onPressed: () {
                                      var log = Log(
                                          title: DateFormat('dd MM yyyy')
                                              .format(DateTime.now()),
                                          content: "",
                                          timeCreated: DateTime.now());
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => NoteEditor(
                                                    log: null,
                                                  ))).then((value) {
                                        setState(() {});
                                      });
                                    },
                                    child: const Text("Create a log"),
                                  )
                                ],
                              ),
                            );
                          }
                        },
                      )),
                    ),
                  ],
                ),
              );
            }),
      ),
    );
  }
}
