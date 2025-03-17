import 'package:flutter/material.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Back button and logo row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E8388),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),

                    // App logo on the right
                    Image.asset(
                      'assets/images/pharmafive_512x512.png',
                      width: 100,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.medical_services_outlined,
                        color: Colors.blue.shade700,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tagline aligned to the left
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join us today for easy',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                      Text(
                        'medicine management!',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Registration form fields - improved design
                buildTextField("Full Name"),
                const SizedBox(height: 12),
                buildTextField("Organization"),
                const SizedBox(height: 12),
                buildTextField("Mobile Number"),
                const SizedBox(height: 12),
                buildTextField("Email"),
                const SizedBox(height: 12),
                buildPasswordField(),

                const SizedBox(height: 24),

                // Sign Up button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle sign up
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E8388),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // OR divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        'or',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),

                const SizedBox(height: 12),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to login screen
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Terms and Privacy Policy
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      children: [
                        const TextSpan(
                          text: 'By signing in, you agree to the ',
                        ),
                        TextSpan(
                          text: 'Terms and Privacy Policy',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
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
    );
  }

  Widget buildTextField(String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Lighter gray background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
          ),
          border: InputBorder.none, // No border
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          // prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade500) : null,
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
        textAlignVertical: TextAlignVertical.center, // Prevents the text from jumping
      ),
    );
  }

  Widget buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Lighter gray background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        obscureText: _obscurePassword,
        textAlignVertical: TextAlignVertical.center, // Prevents the text from jumping
        decoration: InputDecoration(
          labelText: "Password",
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          // prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade500),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey.shade600,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
      ),
    );
  }
}