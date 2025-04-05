import 'package:flutter/material.dart';
import 'package:pharma_five/ui/walk_through_screen.dart';
import 'dart:async';
import 'login_screen.dart';



class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Animation Controller
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    // Scale + Fade Animation
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward(); // Start animation

    // Navigate to Login Screen after animation
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WalkthroughScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Clean up animation controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          /*Image.asset(
            'assets/images/pharma_five_bg.jpg', // Provided background
            fit: BoxFit.cover,
          ),*/
          Center(
            child: ScaleTransition(
              scale: _animation,
              child: FadeTransition(
                opacity: _animation,
                child: Image.asset(
                  'assets/images/pharmafive_1024x1024.png', // Logo
                  height: 150,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}