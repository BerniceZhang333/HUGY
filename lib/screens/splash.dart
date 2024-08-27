import 'package:flutter/material.dart';
import 'package:hugy/screens/dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugy/screens/home.dart';
import 'package:hugy/screens/registration.dart';

import 'dart:math';

class TwinkleLittleStar extends StatelessWidget {
  const TwinkleLittleStar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.0,
      height: 1.0,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

class Space extends StatefulWidget {
  const Space({super.key, required this.opacity});

  final Animation<double> opacity;

  @override
  _SpaceState createState() => _SpaceState();
}

class _SpaceState extends State<Space> {
  final int _starCount = 300;

  List<Widget> _stars = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // We generate our stars in this method so that it builds only once
    // but after the initState method has finished running.
    _stars = _generateStars();
  }

  List<Widget> _generateStars() {
    return List.generate(_starCount, (index) {
      List<double> xy = _getRandomPosition(context);
      return Positioned(
        top: xy[0],
        left: xy[1],
        child: const TwinkleLittleStar(),
      );
    });
  }

  List<double> _getRandomPosition(BuildContext context) {
    // We get the dimensions of the screen and use them to generate random coordinates
    double x = MediaQuery.of(context).size.height;
    double y = MediaQuery.of(context).size.width;

    double randomX =
        double.parse((Random().nextDouble() * x).toStringAsFixed(3));
    double randomY =
        double.parse((Random().nextDouble() * y).toStringAsFixed(3));

    return [randomX, randomY];
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.opacity.value,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          color: Colors.black,
          child: Stack(
            children: _stars,
          ),
        ),
      ),
    );
  }
}

class IntroTitle extends StatelessWidget {
  const IntroTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      "HUGY...",
      style: TextStyle(
        color: Color.fromARGB(255, 241, 190, 19),
        fontSize: 72.0,
      ),
    );
  }
}

class CrawlingText extends StatelessWidget {
  const CrawlingText(
      {super.key,
      required this.topMargin,
      required this.bottomMargin,
      required this.opacity});

  // The `topMargin` and `bottomMargin` values are what are used to acheive the crawling effect
  final Animation<double> topMargin;
  final Animation<double> bottomMargin;
  final Animation<double> opacity;

  final TextStyle _crawlingTextStyle = const TextStyle(
    color: Color(0xFFFFC500),
    fontSize: 40.0,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    final double maxWidthConstraint = MediaQuery.of(context).size.width * 0.6;

    return Opacity(
      opacity: opacity.value,
      child: Center(
        child: Transform(
          // This transformation adjusts it's child to achieve the perspective angle we want
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.007)
            ..rotateX(5.6),
          alignment: FractionalOffset.center,
          child: Container(
            // Adjust the margins above and below the text to make it simulate upward movement
            margin: EdgeInsets.only(
                top: topMargin.value, bottom: bottomMargin.value),
            child: FittedBox(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: maxWidthConstraint < 500
                      ? MediaQuery.of(context).size.width
                      : maxWidthConstraint,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 64.0),
                child: Column(
                  children: [
                    Text(
                      'Episode VII\nTHE FORCE AWAKENS',
                      textAlign: TextAlign.center,
                      style: _crawlingTextStyle,
                    ),
                    const IntroTitle(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final user = FirebaseAuth.instance.currentUser;
  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Future.delayed(const Duration(seconds: 0), () {
      setState(() {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (BuildContext context) {
          return const AuthGate();
        }));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: const Center(
          child: IntroTitle(),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext, AsyncSnapshot<User?> snapshot) {
          if (snapshot.hasData) {
            return const Home();
          } else {
            return const Registration();
          }
        });
  }
}
