import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hugy/auth/firebase.dart';
import 'package:hugy/screens/activities/meditation_page.dart';
import 'package:hugy/screens/contacts.dart';
import 'package:hugy/screens/advice.dart';
import 'package:hugy/screens/journal.dart';
import 'package:hugy/screens/profile.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int coins = 0;

  @override
  void initState() {
    super.initState();
    _loadCoins();
  }

  void _loadCoins() async {
    int value = await AuthService().getCoins();
    setState(() {
      coins = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          _buildUserInfo(),
        ],
      ),
      body: _buildDashboard(),
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Colors.yellow),
          const SizedBox(width: 4),
          Text('$coins', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfilePage())),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(FirebaseAuth
                      .instance.currentUser?.photoURL ??
                  "https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildDashboardItem(
          icon: Icons.chat,
          title: "Chat with AI",
          color: Colors.blue,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ContactsPage())),
        ),
        _buildDashboardItem(
          icon: Icons.book,
          title: "Add Journal Entry",
          color: Colors.red,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const JournalPage())),
        ),
        _buildDashboardItem(
          icon: Icons.self_improvement,
          title: "Meditate",
          color: Colors.green,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MeditationPage())),
        ),
        _buildDashboardItem(
          icon: Icons.lightbulb,
          title: "Recommendations",
          color: Colors.orange,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const DiscoverPage())),
        ),
      ],
    );
  }

  Widget _buildDashboardItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
