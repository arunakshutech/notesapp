import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:notes/Screens/Notescreating/NotesScreen.dart';


class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to HomeScreen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NotesScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 203, 112),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display Logo
            Image.asset(
              'assets/logo.png', // Make sure your logo is in assets folder
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            // Animated Text
            DefaultTextStyle(
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 72, 72, 72),
              ),
              child: AnimatedTextKit(
                animatedTexts: [
                  FadeAnimatedText('Developed by Arunkumar'),
                  FadeAnimatedText('Flutter Developer'),
                ],
                repeatForever: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
