import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugy/screens/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

Future<void> spinServer() async {
  // Spin up render.com free plan
  String endpoint = "https://hugy-server.onrender.com";
  // send get request
  var response = await http.get(Uri.parse(endpoint));
  Logger('spinServer').info(response.body);
  return;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const App());
  String key = await FirebaseFirestore.instance
      .collection("keys")
      .doc('openai_key')
      .get()
      .then((value) => value.data()?['data']);
  Gemini.init(apiKey: key);
  await spinServer();
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
   
        home: const AuthGate(),
      );
    
  }
}
