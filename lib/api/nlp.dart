import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

var endpoint = "https://hugy-server.onrender.com";

Future<String?> getMood(String text) async {
  print("getting mood");
  Uri uri = Uri.parse("$endpoint/predict");
  try {
    var response = await http.post(uri,
        body: jsonEncode({"text": text}),
        headers: {HttpHeaders.contentTypeHeader: "application/json"});
    print(response.body);
    return jsonDecode(response.body)['prediction'];
  } catch (e) {
    return "joy";
  }
}
