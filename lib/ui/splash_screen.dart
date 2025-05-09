import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:pharma_five/ui/login_screen.dart';
import 'package:pharma_five/ui/walk_through_screen.dart';
import 'package:pharma_five/ui/doctor/user_dashboard.dart';
import 'package:pharma_five/ui/admin/admin_dashboard.dart';
import '../helper/shared_preferences.dart';
import '../service/api_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _checkAndClearSession().then((_) {
      _navigateAfterDelay();
    });
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: isError ? Colors.red : const Color(0xff0e63ff),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }


  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));

    // Check internet connectivity first
    final isConnected = await InternetConnection().hasInternetAccess;
    if (!isConnected) {
      _showToast("No internet connection. Please check your connection and try again.", isError: true);
      // You could add a retry button or auto-retry mechanism here
    }

    await SharedPreferenceHelper.init();
    final isLoggedIn = await SharedPreferenceHelper.isLoggedIn();
    final role = await SharedPreferenceHelper.getUserType();
    final status = await SharedPreferenceHelper.getUserStatus();

    // Rest of your navigation logic remains the same
    if (isLoggedIn) {
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else if (role == 'user' && status == 'active') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WalkthroughScreen()),
      );
    }
  }

  /*Future<void> _checkAndClearSession() async {
    await SharedPreferenceHelper.init();
    final isLoggedIn = await SharedPreferenceHelper.isLoggedIn();
    final email = await SharedPreferenceHelper.getUserEmail();
    final installationId = await SharedPreferenceHelper.getInstallationId();

    // Generate a unique installation ID if it doesn't exist
    if (installationId == null) {
      final newInstallationId = DateTime.now().millisecondsSinceEpoch.toString();
      await SharedPreferenceHelper.setInstallationId(newInstallationId);

      // If user credentials exist but installation ID doesn't,
      // this indicates a reinstall scenario
      if (isLoggedIn && email != null && email.isNotEmpty) {
        try {
          debugPrint("App reinstalled: Logging out $email");
          await ApiService().logoutUser(userEmail: email);
        } catch (e) {
          debugPrint("Logout API error: $e");
        } finally {
          // Clear session after logout attempt regardless of success/failure
          await SharedPreferenceHelper.clearSession();
          // Set the new installation ID after clearing
          await SharedPreferenceHelper.setInstallationId(newInstallationId);
        }
      }
    }
  }*/

  Future<void> _checkAndClearSession() async {
    await SharedPreferenceHelper.init();
    final isLoggedIn = await SharedPreferenceHelper.isLoggedIn();
    final email = await SharedPreferenceHelper.getUserEmail();
    final installationId = await SharedPreferenceHelper.getInstallationId();

    // Reinstall detection: No installation ID stored
    if (installationId == null) {
      final newInstallationId = DateTime.now().millisecondsSinceEpoch.toString();

      if (isLoggedIn && email != null && email.isNotEmpty) {
        try {
          debugPrint("🚨 App reinstalled: Logging out $email");
          await ApiService().logoutUser(userEmail: email);
        } catch (e) {
          debugPrint("Logout API error on reinstall: $e");
        } finally {
          await SharedPreferenceHelper.clearSession();
        }
      }

      // Save the new installation ID for future launches
      await SharedPreferenceHelper.setInstallationId(newInstallationId);
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: ScaleTransition(
              scale: _animation,
              child: FadeTransition(
                opacity: _animation,
                child: Image.asset(
                  'assets/images/pharmafive_1024x1024.png',
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
