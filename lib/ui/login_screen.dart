import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:pharma_five/ui/admin/admin_dashboard.dart';
import 'package:pharma_five/ui/forgot_password_screen.dart';
import 'package:pharma_five/ui/registration_screen.dart';
import 'package:pharma_five/ui/walk_through_screen.dart';
import '../helper/color_manager.dart';
import '../helper/shared_preferences.dart';
import '../service/api_service.dart';
import 'package:flutter/gestures.dart';
import 'admin_approval_screen.dart';
import 'doctor/user_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _wasDisconnected = false;

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

  @override
  void initState() {
    super.initState();
    _checkAndClearSession();
    // Check initial connectivity status but don't show toast for initial connected state
    InternetConnection().hasInternetAccess.then((connected) {
      if (!connected) {
        _wasDisconnected = true;
        _showToast("No internet connection", isError: true);
      }
    });

    // Listen for internet connectivity changes
    InternetConnection().onStatusChange.listen((status) {
      if (status == InternetStatus.disconnected) {
        _wasDisconnected = true;
        _showToast("Internet disconnected", isError: true);
      } else if (_wasDisconnected) {
        // Only show the "connected" toast if previously disconnected
        _wasDisconnected = false;
        _showToast("Internet connected");
      }
    });
  }

  Future<void> _checkAndClearSession() async {
    await SharedPreferenceHelper.init();
    final isLoggedIn = await SharedPreferenceHelper.isLoggedIn();
    final email = await SharedPreferenceHelper.getUserEmail();

    if (isLoggedIn && email != null && email.isNotEmpty) {
      await ApiService().logoutUser(userEmail: email);
      await SharedPreferenceHelper.clearSession();
    }
  }

  Future<void> _validateForm() async {
    try {
      final isConnected = await InternetConnection().hasInternetAccess;
      if (!isConnected) {
        _showToast("No internet connection. Please check your connection and try again.", isError: true);
        return;
      }

      await SharedPreferenceHelper.init();

      if (_formKey.currentState!.validate()) {
        setState(() => _isLoading = true);

        final email = _emailController.text.trim();
        final password = _passwordController.text;

        final loginResult = await ApiService().userLogin(email: email, password: password);

        final bool success = loginResult?['success'] ?? false;
        final String message = loginResult?['message'] ?? '';
        final Map<String, dynamic>? data = loginResult?['data'];
        final String role = loginResult?['role'] ?? '';
        final String status = loginResult?['status'] ?? '';

        await SharedPreferenceHelper.setLoggedIn(true);
        await SharedPreferenceHelper.setUserEmail(email);
        await SharedPreferenceHelper.setUserType(role);
        await SharedPreferenceHelper.setUserStatus(status);

        if (success && data != null) {

          _showToast("${role[0].toUpperCase()}${role.substring(1)} login successful!");

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
          }
        } else if (!success &&
            (message.contains("Account is not ACTIVE. Current status: Pending") || message.contains("Account is not ACTIVE. Current status: Reject"))) {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
          );
        } else {
          _showToast(message.isNotEmpty ? message : "Login failed.", isError: true);
        }
      }
    } catch (e) {
      _showToast("Login failed. Please try again.", isError: true);
      debugPrint('Login error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back + Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => {
                          Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => WalkthroughScreen()),
                          )
                        },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xff0e63ff),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF9ABEE3),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.arrow_back_ios_new,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                        Image.asset(
                          'assets/images/pharmafive_512x512.png',
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.medical_services_outlined,
                                  color: Colors.blue.shade700, size: 30),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Login to Pharma Five Imports',
                      style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Join us today for easy medicine',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const Text(
                      'management!',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),

                    const SizedBox(height: 30),

                    buildTextField("Email or username", _emailController),
                    buildPasswordField(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        /*onPressed: (){
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => AdminDashboard()),
                          );
                        },*/
                        onPressed: _isLoading ? null : _validateForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0e63ff),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xff0e63ff)),
                          ),
                        )
                            : const Text('Log In',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RegistrationScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Color(0xff0e63ff)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Sign Up',
                            style: TextStyle(
                                color: Color(0xff0e63ff),
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: RichText(
                          textAlign: TextAlign.start,
                          text: TextSpan(
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade600),
                            children: [
                              const TextSpan(
                                  text: 'By signing in, you agree to the '),
                              TextSpan(
                                text: 'Terms and Privacy Policy',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        );
                      },
                      child: Text(
                        'I forgot my password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.navBorder,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value
                .trim()
                .isEmpty) {
              return "$label is required";
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }


  Widget buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: "Password",
            labelStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey.shade600,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Password is required";
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}