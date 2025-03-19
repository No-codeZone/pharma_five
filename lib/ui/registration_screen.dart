import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pharma_five/ui/login_screen.dart';
import 'package:pharma_five/ui/walk_through_screen.dart';
import 'package:fluttertoast/fluttertoast.dart'; // Add this import
import '../service/api_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _validationMessage;
  bool _isLoading = false;

  bool _isNameValid = true;
  bool _isOrganizationValid = true;
  bool _isMobileValid = true;
  bool _isEmailValid = true;
  bool _isPasswordValid = true;

  // Function to show toast message
  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: isError ? Colors.red : const Color(0xFF0E8388),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _validateForm() async {
    // Reset all validation states
    setState(() {
      _validationMessage = null;
      _isLoading = false;
      _isNameValid = true;
      _isOrganizationValid = true;
      _isMobileValid = true;
      _isEmailValid = true;
      _isPasswordValid = true;
    });

    bool hasError = false;

    // Check name field
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _isNameValid = false;
        hasError = true;
      });
    }

    // Check organization field
    if (_organizationController.text.trim().isEmpty) {
      setState(() {
        _isOrganizationValid = false;
        hasError = true;
      });
    }

    // Check mobile field
    if (_mobileController.text.trim().isEmpty || _mobileController.text.length != 10) {
      setState(() {
        _isMobileValid = false;
        hasError = true;
        if (_mobileController.text.trim().isEmpty) {
          _validationMessage = "Please enter mobile number";
        } else {
          _validationMessage = "Mobile number must be 10 digits";
        }
      });
    }

    // Check email field
    if (_emailController.text.trim().isEmpty ||
        !RegExp(r'^[a-zA-Z0-9.*%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(_emailController.text)) {
      setState(() {
        _isEmailValid = false;
        hasError = true;
        if (_emailController.text.trim().isEmpty) {
          _validationMessage = "Please enter email address";
        } else {
          _validationMessage = "Please enter a valid email address";
        }
      });
    }

    // Check password field
    if (_passwordController.text.trim().isEmpty || _passwordController.text.length < 8) {
      setState(() {
        _isPasswordValid = false;
        hasError = true;
        if (_passwordController.text.trim().isEmpty) {
          _validationMessage = "Please enter password";
        } else {
          _validationMessage = "Password must include at least 8 characters";
        }
      });
    }

    // If any field has an error, return early
    if (hasError) {
      if (_validationMessage == null) {
        _validationMessage = "Please fill in all fields!";
      }
      return;
    }

    // If we reach here, all validations passed
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      // Comment out or replace connectivity check
      // var connectivityResult = await Connectivity().checkConnectivity();
      bool hasInternet = true; // Assume connectivity for testing

      if (!mounted) return;

      if (!hasInternet) {
        setState(() {
          _isLoading = false;
          _validationMessage = "No internet connection. Please check your network.";
        });
        return;
      }

      // Use a timeout for the API call
      bool success = false;
      try {
        success = await ApiService().registerUser(
          name: _nameController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          email: _emailController.text.trim(),
          organisationName: _organizationController.text.trim(),
          password: _passwordController.text.trim(),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            // This will be caught by the outer try-catch
            throw TimeoutException("Request timed out!");
          },
        );
      } on TimeoutException {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _validationMessage = "Request timed out! Please try again.";
          });
          _showToast("Request timed out! Please try again.", isError: true);
        }
        return;
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _showToast("Registration successful!");

        // Small delay to ensure toast is visible before navigation
        Future.delayed(Duration(milliseconds: 500), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        });
      } else {
        setState(() {
          _validationMessage = "Registration failed. Try again!";
        });
        _showToast("Registration failed. Try again!", isError: true);
      }
    } catch (e) {
      debugPrint("Error in validateForm: $e");

      setState(() {
        _isLoading = false;
      });

      if (e is TimeoutException) {
        setState(() {
          _validationMessage = "Request timed out! Please try again.";
        });
        _showToast("Request timed out! Please try again.", isError: true);
      } else {
        setState(() {
          _validationMessage = "An unexpected error occurred.";
        });
        _showToast("An unexpected error occurred.", isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button and Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => WalkthroughScreen()),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E8388),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF5AB1B4),
                              width: 4,
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
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.medical_services_outlined,
                          color: Colors.blue.shade700,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Headline
                  Text(
                    'Join us today for easy\nmedicine management!',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 24),

                  // Form Fields
                  buildTextField("Full Name", _nameController),
                  buildTextField("Organization", _organizationController),
                  buildMobileNumberField(),
                  buildTextField("Email", _emailController, isEmail: true),
                  buildPasswordField(),

                  // const SizedBox(height: 5),

                  // Validation Message
                  if (_validationMessage != null)
                    Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _validationMessage!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Sign Up Button with Loader
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validateForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E8388),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _isLoading
                          ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0E8388)),
                        ),
                      )
                          : const Text('Sign Up',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // OR separator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 14)),
                      ),
                      // Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Color(0xFF0E8388)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Login',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0E8388))),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Terms and Privacy Policy
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool isEmail = false, bool isValid = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType:
          isEmail ? TextInputType.emailAddress : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: isValid ? BorderSide.none : BorderSide(color: const Color(0xFF0E8388), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: isValid ? BorderSide.none : BorderSide(color: const Color(0xFF0E8388), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: const Color(0xFF0E8388), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget buildMobileNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.number,
          maxLength: 10,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            labelText: "Mobile Number",
            labelStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: _isMobileValid ? BorderSide.none : BorderSide(color: const Color(0xFF0E8388), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: _isMobileValid ? BorderSide.none : BorderSide(color: const Color(0xFF0E8388), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: const Color(0xFF0E8388), width: 2),
            ),
            counterText: "",
          ),
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
              borderSide: _isPasswordValid ? BorderSide.none : BorderSide(color: const Color(0xFF0E8388), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: _isPasswordValid ? BorderSide.none : BorderSide(color: const Color(0xFF0E8388), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: const Color(0xFF0E8388), width: 2),
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
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}