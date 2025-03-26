import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../helper/shared_preferences.dart';

class ApiService {
  // Base URL for API endpoints
  final String baseUrl = "http://192.168.xxx.xx:8080/api/registration";

  // Admin credentials - in a real app, these should be stored securely
  // or managed through a proper backend system
  final String adminEmail = "admin@pharmafive.com";
  final String adminPassword = "Admin@220325";
  final int defaultPageSize = 10;

  /// Authenticate an admin user
  Future<bool> adminLogin({
    required String email,
    required String password,
  }) async {
    if (email.trim() == adminEmail && password == adminPassword) {
      await SharedPreferenceHelper.setLoggedIn(true);
      await SharedPreferenceHelper.setUserEmail(email);
      return true;
    }
    return false;
  }

  /// Authenticate a regular user through API
  Future<bool> userLogin({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      debugPrint("login/Response\t${response.body.toString()}");

      if (response.statusCode == 200) {
        await SharedPreferenceHelper.setLoggedIn(true);
        await SharedPreferenceHelper.setUserEmail(email);
        return true;
      } else {
        debugPrint('Login Error: ${response.body}');
        return false;
      }
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException in login API: $e');
      throw e;
    } catch (e) {
      debugPrint('Unexpected error in login API: $e');
      return false;
    }
  }

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
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "mobileNumber": mobileNumber,
          "email": email,
          "organisationName": organisationName,
          "password": password,
        }),
      );

      debugPrint("register/Response\t${response.body.toString()}");

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Registration Error: ${response.body}');
        return false;
      }
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException in registration API: $e');
      throw e;
    } catch (e) {
      debugPrint('Unexpected error in registration API: $e');
      return false;
    }
  }

  /// Fetch users with pagination and status filtering
  /*Future<Map<String, dynamic>> getUsers(
      {int page = 0, int size = 10, String? status}) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
    };

    // Map status to backend status values
    switch (status) {
      case 'Pending':
        queryParams['status'] = 'PENDING';
        break;
      case 'Approved':
        queryParams['status'] = 'ACTIVE';
        break;
      case 'Rejected':
        queryParams['status'] = 'REJECTED';
        break;
    }

    // Construct URL with query parameters
    final url =
    Uri.parse('$baseUrl/search').replace(queryParameters: queryParams);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // Return the entire response to maintain pagination info
        return json.decode(response.body);
      } else {
        debugPrint('Error fetching users: ${response.body}');
        throw Exception('Failed to load users===${response.body}');
      }
    } catch (e) {
      debugPrint('Error in getUsers: $e');
      return {'content': [], 'totalPages': 0, 'last': true};
    }
  }*/

  /// Fetch users with pagination and status filtering
  Future<Map<String, dynamic>> getUsers({
    int page = 0,
    int size = 10,
    String? search = '',
    String? status,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      'search': search ?? '',
    };

    // Map status to backend status values
    if (status != null && status.isNotEmpty) {
      switch (status.toLowerCase()) {
        case 'pending':
          queryParams['status'] = 'Pending';
          break;
        case 'approved':
          queryParams['status'] = 'Active';
          break;
        case 'rejected':
          queryParams['status'] = 'Reject';
          break;
      }
    }

    final url = Uri.parse('$baseUrl/search').replace(queryParameters: queryParams);

    try {
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      debugPrint("getUsers/Response\t${response.body.toString()}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Error fetching users: ${response.body}');
        throw Exception('Failed to load users: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in getUsers: $e');
      return {'content': [], 'totalPages': 0, 'last': true};
    }
  }


  // Helper method to map backend status to frontend display status
  String _mapStatusToFrontend(String backendStatus) {
    switch (backendStatus) {
      case 'PENDING':
        return 'Pending';
      case 'ACTIVE':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }
}
