import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isSubmitting = false;
  bool _isOtpSent = false;
  int _remainingSeconds = 60;
  Timer? _timer;

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isOtpValid = false;

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: isError ? Colors.red : const Color(0xff0e63ff),
      textColor: Colors.white,
      gravity: ToastGravity.BOTTOM,
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _startCountdownTimer() {
    _remainingSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 0) {
        timer.cancel();
      }
      setState(() {
        _remainingSeconds--;
      });
    });
  }

  Future<void> _sendOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      await Future.delayed(const Duration(seconds: 1)); // Simulated API

      _showToast("OTP sent to ${_emailController.text.trim()}");
      _otpController.clear();
      _startCountdownTimer();

      setState(() {
        _isSubmitting = false;
        _isOtpSent = true;
        _isOtpValid = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    if (_formKey.currentState!.validate()) {
      if (_otpController.text.length != 6) {
        _showToast("Enter a valid 6-digit OTP", isError: true);
        return;
      }

      setState(() => _isSubmitting = true);
      await Future.delayed(const Duration(seconds: 2)); // Simulated API

      _showToast("Password reset successful");
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xff0e63ff),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF9ABEE3), width: 2),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      ),
                    ),
                    Image.asset(
                      'assets/images/pharmafive_512x512.png',
                      width: 80,
                      height: 80,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.medical_services_outlined, color: Colors.blue, size: 30),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Reset Your Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('A 6-digit OTP will be sent to your email',
                    style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 20),

                _buildTextField("Email", _emailController, TextInputType.emailAddress, (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  return null;
                }),

                _buildPasswordField(
                  "New Password",
                  _newPasswordController,
                  _obscureNewPassword,
                      () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                      (val) => val == null || val.length < 8 ? 'Minimum 8 characters' : null,
                ),

                _buildPasswordField(
                  "Confirm Password",
                  _confirmPasswordController,
                  _obscureConfirmPassword,
                      () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      (val) => val != _newPasswordController.text ? "Passwords don't match" : null,
                ),

                if (_isOtpSent)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: "Enter OTP",
                        hintText: "000000",
                        counterText: '',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _isOtpValid = value.trim().length == 6;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.length != 6) {
                          return "Please enter 6-digit OTP";
                        }
                        return null;
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                if (_isOtpSent && _remainingSeconds > 0)
                  Text(
                    'Time remaining: ${_formatTime(_remainingSeconds)}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                  ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : _isOtpSent
                        ? (_isOtpValid ? _verifyOTP : null)
                        : _sendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0e63ff),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                        : Text(_isOtpSent ? "Verify OTP" : "Reset Password"),
                  ),
                ),

                if (_isOtpSent && _remainingSeconds <= 0)
                  TextButton(
                    onPressed: _sendOTP,
                    child: const Text("Resend OTP", style: TextStyle(color: Color(0xff0e63ff))),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      TextInputType inputType, FormFieldValidator<String> validator) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
      String label,
      TextEditingController controller,
      bool obscureText,
      VoidCallback toggleVisibility,
      FormFieldValidator<String> validator,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: toggleVisibility,
          ),
        ),
      ),
    );
  }
}
