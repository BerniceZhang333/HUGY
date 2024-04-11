import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hugy/auth/firebase.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class LifeTimer extends StatefulWidget {
  const LifeTimer({super.key});

  @override
  State<LifeTimer> createState() => _LifeTimerState();
}

class _LifeTimerState extends State<LifeTimer> {
  Future<DateTime?> getUserBirthday() async {
    final user = await FirebaseAuth.instance.currentUser;
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    try {
      if (!(userDoc.data() as Map).containsKey("birthday")) {
        return null;
      }

      final birthday = userDoc.get("birthday");
      return birthday.toDate();
    } catch (e) {
      return null;
    }
  }

  DateTime? birthday;
  late int yearsOld;

  @override
  void initState() {
    super.initState();
    getUserBirthday().then((value) {
      setState(() {
        birthday = value;
      });
    });
  }

  Future<void> addBirthday(DateTime birthday) async {
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .update({"birthday": birthday});
  }

  Widget buildDatePicker() {
    return SizedBox(
      width: 200,
      height: 300,
      child: Center(
        child: ElevatedButton(
          onPressed: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                birthday = picked;
              });
              addBirthday(picked);
            }
          },
          child: const Text('Select your birthday'),
        ),
      ),
    );
  }

  // construct time since we were born

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    yearsOld = birthday != null
        ? DateTime.now().difference(birthday!).inDays ~/ 365
        : 0;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Center(
            child: SizedBox(
              width: 300,
              height: 250,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  birthday == null
                      ? const Text("Please set your birthday",
                          style: TextStyle(fontSize: 24))
                      : SizedBox(),
                  const SizedBox(height: 30),
                  Expanded(
                    child: CustomPaint(
                      willChange: false,
                      painter: Battery(
                        currentLife: DateTime.now()
                            .difference(birthday ?? DateTime.now()),
                      ),
                      child: SizedBox(
                        child: Center(
                          child: Text(
                            "${yearsOld / 80 * 100}%",
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: "Assuming you live to 80 years old, you are ",
                        style: const TextStyle(fontSize: 24),
                        children: [
                          TextSpan(
                            text: "${yearsOld / 80 * 100}% through your life",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (birthday == null)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => buildDatePicker(),
                          ),
                        );
                      },
                      child: const Text('Set Birthday'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Battery extends CustomPainter {
  // Duration maxLife; // lifespan
  // Duration currentLife; // birthday
  Duration maxLife = const Duration(days: 365 * 80);
  Duration currentLife;

  Battery({required this.currentLife});

  @override
  void paint(Canvas canvas, Size size) {
    var percentage =
        ((currentLife.inSeconds / maxLife.inSeconds) * 100).clamp(0, 100);
    final paint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;

    double half_width = size.width;
    double half_height = size.height;

    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, half_width, half_height, Radius.circular(10)),
      paint,
    );

    paint.color = const Color.fromARGB(255, 141, 232, 99);

    canvas.drawRRect(
      RRect.fromLTRBR(
          0,
          0,
          half_width *
              (currentLife.inSeconds / maxLife.inSeconds).clamp(0, 100),
          half_height,
          Radius.circular(10)),
      paint,
    );

    // paint square border at right side of green
    canvas.drawRRect(
      RRect.fromLTRBR(
          10,
          0,
          half_width *
              ((currentLife.inSeconds / maxLife.inSeconds).clamp(0, 100)),
          half_height,
          percentage >= 100 ? Radius.circular(10) : Radius.zero),
      paint,
    );

    paint.color = Colors.white;
    paint.strokeWidth = 15;
    paint.style = PaintingStyle.stroke;

    canvas.drawRRect(
        RRect.fromLTRBR(
            -15, -15, half_width + 15, half_height + 15, Radius.circular(10)),
        paint);

    // positive terminal

    paint.color = Colors.white;
    paint.strokeWidth = 5;
    paint.style = PaintingStyle.fill;

    canvas.drawRRect(
        RRect.fromLTRBR(half_width + 10, half_height / 2 - 20, half_width + 30,
            half_height / 2 + 20, const Radius.circular(10)),
        paint);
    // gap between white border and the green, using transparent
    paint.color = Colors.transparent;
    paint.strokeWidth = 5;
    paint.style = PaintingStyle.stroke;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate != this;
}
