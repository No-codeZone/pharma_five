import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class ApiService {

  // final String baseUrl = "http://localhost:8080/api/registration";

  final String baseUrl = "http://192.168.211.98:8080/api/registration";

  /// Register a new user
  Future<bool> registerUser({
    required String name,
    required String mobileNumber,
    required String email,
    required String organisationName,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/register');

    try {
      final response = await http
          .post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "mobileNumber": mobileNumber,
          "email": email,
          "organisationName": organisationName,
          "password": password,
        }),
      )
      // Note: Don't set timeout here - handle it in the calling function
      // Let the timeout be managed by the calling function
      // This allows us to properly show user-friendly messages
          ;

      debugPrint("register/Response\t${response.body.toString()}");

      if (response.statusCode == 200) {
        return true; // Success
      } else {
        debugPrint('Error: ${response.body}');
        return false;
      }
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException in API: $e');
      // Let the timeout propagate to the calling function
      throw e;
    } catch (e) {
      debugPrint('Unexpected error in API: $e');
      return false;
    }
  }

  /// Fetch users with pagination
  Future<List<dynamic>> getUsers({int page = 0, int size = 5}) async {
    final url = Uri.parse('$baseUrl/search?page=$page&size=$size');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content']; // Assuming the response is paginated
    } else {
      print('Error: ${response.body}');
      return [];
    }
  }

  /// Login User
  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      return true; // Login successful
    } else {
      print('Login Error: ${response.body}');
      return false;
    }
  }
}
