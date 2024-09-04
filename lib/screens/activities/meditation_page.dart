import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hugy/auth/firebase.dart';

class MeditationPage extends StatefulWidget {
  const MeditationPage({Key? key}) : super(key: key);

  @override
  State<MeditationPage> createState() => _MeditationPageState();
}

class _MeditationPageState extends State<MeditationPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _duration = const Duration(minutes: 5);
  bool _isRunning = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 300), // 5 minutes
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String twoDigits(int n) => n.toString().padLeft(2, "0");

  void startTimer() {
    if (!_isRunning) {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_duration.inSeconds > 0) {
          setState(() {
            _duration = Duration(seconds: _duration.inSeconds - 1);
            _controller.value = 1 - (_duration.inSeconds / 300);
          });
        } else {
          stopTimer();
          _showCompletionDialog();
        }
      });
      _controller.forward(from: _controller.value);
    }
  }

  void stopTimer() {
    if (_isRunning) {
      setState(() => _isRunning = false);
      _timer?.cancel();
      _controller.stop();
    }
  }

  void resetTimer() {
    stopTimer();
    setState(() {
      _duration = const Duration(minutes: 5);
      _controller.reset();
    });
  }

  void _showCompletionDialog() {
    AuthService().addCoins(100);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Meditation Complete!"),
        content: const Text("You have earned 100 coins!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[100]!, Colors.blue[400]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Meditation Timer",
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 40),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: _controller.value,
                      strokeWidth: 12,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  Text(
                    "${twoDigits(_duration.inMinutes.remainder(60))}:${twoDigits(_duration.inSeconds.remainder(60))}",
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildButton(
                    onPressed: _isRunning ? stopTimer : startTimer,
                    icon: _isRunning ? Icons.pause : Icons.play_arrow,
                    label: _isRunning ? "Pause" : "Start",
                  ),
                  _buildButton(
                    onPressed: resetTimer,
                    icon: Icons.refresh,
                    label: "Reset",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
      {required VoidCallback onPressed,
      required IconData icon,
      required String label}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.blue[700],
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
