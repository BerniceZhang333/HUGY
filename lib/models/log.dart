import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Log {
  final String? id;
  final String title;
  final String content;
  final DateTime timeCreated;

  Log({
    this.id,
    required this.title,
    required this.content,
    required this.timeCreated,
  });

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "content": content,
      "timeCreated": timeCreated,
    };
  }

  factory Log.fromSnapshot(QueryDocumentSnapshot snapshot) {
    return Log(
        id: snapshot.id,
        content: snapshot['content'],
        title: snapshot['title'],
        timeCreated: snapshot['timeCreated'].toDate());
  }

  factory Log.fromMap(Map<String, dynamic> map) {
    return Log(
        id: map['id'],
        content: map['content'],
        title: map['title'],
        timeCreated: map['timeCreated'].toDate());
  }

  String getTitle() {
    if (DateTime.tryParse(title) == null) {
      // our title is not a datetime anymore
      return title;
    } else {
      // title is still datetime
      return DateFormat('dd MM yyyy').format(timeCreated);
    }
  }

  @override
  // TODO: implement hashCode
  int get hashCode => title.hashCode ^ content.hashCode ^ timeCreated.hashCode;

  static fromDocumentSnapshot(QueryDocumentSnapshot<Object?> log) {
    return Log(
        id: log.id,
        title: log['title'],
        content: log['content'],
        timeCreated: log['timeCreated'].toDate());
  }
}

class LogService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Creater a new firestore connection

  // function to upload a log
  Future<bool> uploadLog(Log entry) async {
    try {
      await _firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('entries')
          .add(entry.toMap());
    } catch (e) {
      print(e);
      return false; // failed to upload log
    }

    return true; //succesfully uploaded the log entry
  }

  Future<void> updateLog(Log entry, String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('entries')
          .doc(id)
          .update(entry.toMap());
    } catch (e) {
      print(e);
    }
  }

  Future<bool> deleteLog(String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('entries')
          .doc(id.toString())
          .delete();
    } catch (e) {
      print(e);
      return false;
    }

    return true;
  }

  Stream<QuerySnapshot> getLastFiveLogs() async* {
    yield* _firestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('entries')
        .where('timeCreated',
            isGreaterThanOrEqualTo:
                DateTime.now().subtract(const Duration(days: 5)))
        .get()
        .asStream();
  }

  Future<DocumentSnapshot> getLog(String id) async {
    return await _firestore.collection('entries').doc(id).get();
  }

  Future<List<QueryDocumentSnapshot>> getLogs() async {
    List<QueryDocumentSnapshot> logs = [];
    await _firestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('entries')
        .get()
        .then((value) {
      for (var element in value.docs) {
        logs.add(element);
      }
    });

    return logs;
  }

  Future<List<QueryDocumentSnapshot>> getLogsByDate(DateTime date) async {
    List<QueryDocumentSnapshot> logs = [];
    var s = _firestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('entries')
        .where('timeCreated', isGreaterThanOrEqualTo: date)
        .where('timeCreated', isLessThan: date.add(const Duration(days: 1)))
        .get();

    await s.then((value) {
      for (var element in value.docs) {
        logs.add(element);
      }
    });

    return logs;
  }
}
