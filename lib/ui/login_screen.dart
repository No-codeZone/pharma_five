import 'package:flutter/material.dart';
import 'package:pharma_five/ui/registration_screen.dart';
import '../helper/color_manager.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailOrPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      print("Login Successful");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/pharma_five_bg.jpg',
            fit: BoxFit.cover,
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/pharma_five_logo.png', height: 50),
                        SizedBox(height: 10),
                        Text(
                          "Welcome",
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Sign in to continue",
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // Login Form
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email or Phone Number Field
                        _buildEmailOrPhoneField("Email or Phone Number", _emailOrPhoneController),
                        SizedBox(height: 20),

                        // Password Field
                        _buildPasswordField("Password", _passwordController, _obscurePassword, () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        }),
                        SizedBox(height: 30),

                        // Login Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.btnPrimary,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _submitForm,
                          child: Text("Login", style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(height: 20),

                        // Sign-up and Forgot Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => RegistrationScreen()),
                                );
                              },
                              child: Text("Sign up", style: TextStyle(color: ColorManager.textPrimary)),
                            ),
                            TextButton(
                              onPressed: () {
                                // Forgot password action
                              },
                              child: Text("Forgot Password", style: TextStyle(color: ColorManager.textPrimary)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Email or Phone Number Field with Validation
  Widget _buildEmailOrPhoneField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: ColorManager.textPrimary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ColorManager.textPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ColorManager.textPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
      style: TextStyle(color: ColorManager.textPrimary),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        bool isEmail = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value);
        bool isPhone = RegExp(r"^\+91[0-9]{10}$").hasMatch(value);
        if (!isEmail && !isPhone) {
          return 'Enter a valid Email or +91XXXXXXXXXX format';
        }
        return null;
      },
    );
  }

  // Password Field with Validation
  Widget _buildPasswordField(String label, TextEditingController controller,
      bool obscureText, VoidCallback toggleVisibility) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: ColorManager.textPrimary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ColorManager.textPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ColorManager.textPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: ColorManager.textPrimary,
          ),
          onPressed: toggleVisibility,
        ),
      ),
      style: TextStyle(color: ColorManager.textPrimary),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }
}