import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../helper/shared_preferences.dart';
import '../model/add_product_request_model.dart';
import '../model/add_product_response_model.dart';
import '../model/login_request_model.dart';
import '../model/login_response_model.dart';
import '../model/product_listing_response_model.dart';
import '../model/product_update_request_model.dart';
import '../model/product_update_response_model.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  // Base URL for API endpoints
  final String baseUrl = "http://ec2-16-171-4-239.eu-north-1.compute.amazonaws.com:8080/api/registration";
  final String baseUrlProduct = "http://ec2-16-171-4-239.eu-north-1.compute.amazonaws.com:8080/api";
  // final String baseUrl = "http://192.168.237.98:8080/api/registration";

  // Admin credentials - in a real app, these should be stored securely
  // or managed through a proper backend system
  final int defaultPageSize = 10;
  final String loginAPI="/login";
  final String registerAPI="/register";
  final String userUpdateAPI="/update-status";
  final String searchUserListingAPI="/search";
  final String getProductListingAPI="/product/list";  //baseUrlProduct
  final String updateProductAPI="/product/update";    //baseUrlProduct
  final String addProductAPI="/product/add";   //baseUrlProduct
  final String bulkProductAPI="/product/upload";   //baseUrlProduct
  final String sendOTPAPI="/send-otp";
  final String resetPasswordAPI="/reset-password";

  /// Authenticate a regular user through API
  Future<Map<String, dynamic>?> userLogin({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl$loginAPI');

    try {
      debugPrint("Sending login request to $url with body: ${jsonEncode({
        "email": email,
        "password": password,
      })}");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      debugPrint("login/Response: ${response.body}");

      final Map<String, dynamic> data = jsonDecode(response.body);
      final bool success = data['success'] ?? false;
      final String message = data['message'] ?? "Login failed.";
      final Map<String, dynamic>? userData = data['data'];

      if (response.statusCode == 200 && success && userData != null) {
        final String status = userData['status']?.toString().toLowerCase() ?? 'pending';
        final String role = userData['role']?.toString().toLowerCase() ?? 'user';

        // Save to shared preferences
        await SharedPreferenceHelper.setLoggedIn(true);
        await SharedPreferenceHelper.setUserEmail(email);
        await SharedPreferenceHelper.setUserType(role);
        await SharedPreferenceHelper.setUserStatus(status);

        return {
          'success': true,
          'message': message,
          'data': userData,
          'status': status,
          'role': role,
        };
      } else {
        // Always return server message
        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      debugPrint('Unexpected error in login API: $e');
      return {
        "success": false,
        "message": "An error occurred. Please try again.",
      };
    }
  }

  /// Register a new user
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String mobileNumber,
    required String email,
    required String organisationName,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl${registerAPI}');

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

      debugPrint("register/Response: ${response.body}");

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "message": responseData['message'] ?? 'Registration successful'};
      } else {
        return {"success": false, "message": responseData['message'] ?? 'Registration failed'};
      }
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException in registration API: $e');
      throw TimeoutException('Request timed out');
    } catch (e) {
      debugPrint('Unexpected error in registration API: $e');
      return {"success": false, "message": "Unexpected error occurred"};
    }
  }

  /// Fetch users with pagination and status filtering
  Future<Map<String, dynamic>> getUsers({
    int page = 0,
    int size = 10,
    String? search = '',
    String? status,
    // bool excludeAdmin = true, // New parameter
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      'search': search ?? '',
      // 'excludeAdmin': excludeAdmin.toString(), // Add this parameter
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

    final url = Uri.parse('$baseUrl${searchUserListingAPI}').replace(queryParameters: queryParams);

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

  ///Logout regular user
  Future<void> logoutUser({required String userEmail}) async {
    final url = Uri.parse('$baseUrl/logout').replace(queryParameters: {
      'email': userEmail,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('Logout API response: Logout ${response.statusCode} - ${response.body}');
    } catch (e) {
      debugPrint('Logout API failed: $e');
    }
  }

  /// Fetch products with pagination and search filtering
  Future<List<ProductListingResponseModel>> fetchProductList() async {
    final url = Uri.parse('$baseUrlProduct$getProductListingAPI');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint("fetchProductList/Response => ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Assuming the response is a plain array: [ {}, {}, ... ]
        final List<ProductListingResponseModel> products =
        (data as List).map((item) => ProductListingResponseModel.fromJson(item)).toList();

        return products;
      } else {
        debugPrint('Error fetching product list: ${response.body}');
        throw Exception('Failed to load product list: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception in fetchProductList: $e');
      return [];
    }
  }

  ///Add product
  Future<Map<String, dynamic>?> addProduct({
    required String medicineName,
    required String genericName,
    required String manufacturedBy,
    required String indication,
    required AddProductRequestModel requestModel,
  }) async {
    final url = Uri.parse('$baseUrlProduct$addProductAPI');

    try {
      // Option 1: Use the requestModel directly
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestModel.toJson()), // Assuming requestModel has a toJson method
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      debugPrint("addProduct/Response: ${response.body}");

      // Check if response body is empty or not valid JSON
      if (response.statusCode == 200) {
        return {"success": true, "message": responseData['message'] ?? 'Product added successful !'};
      } else {
        return {"success": false, "message": responseData['message'] ?? 'Product adding failed !'};
      }
    } catch (e) {
      debugPrint('Unexpected error in addProduct API: $e');
      return {'success': false, 'message': 'API connection error: $e'};
    }
  }

  ///Update product
  Future<ProductUpdateResponseModel?> updateProduct(ProductUpdateRequestModel requestModel) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrlProduct$updateProductAPI'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestModel.toJson()),
      );

      if (response.statusCode == 200) {
        return ProductUpdateResponseModel.fromJson(jsonDecode(response.body));
      } else {
        debugPrint('Failed to update product. Status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception when updating product: $e');
      return null;
    }
  }

  ///Send OTP
  Future<Map<String, dynamic>?> sendOTP({
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl$sendOTPAPI');

    try {
      debugPrint("Sending OTP request to $url with body: ${jsonEncode({
        "email": email,
      })}");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
        }),
      );

      debugPrint("sendOTP/Response: ${response.body}");

      final Map<String, dynamic> data = jsonDecode(response.body);
      final bool success = data['success'] ?? false;
      final String message = data['message'] ?? "OTP send failed.";

      if (response.statusCode == 200 && success) {
        return {
          'success': true,
          'message': message,
        };
      } else {
        // Always return server message
        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      debugPrint('Unexpected error in sendOTP API: $e');
      return {
        "success": false,
        "message": "An error occurred. Please try again.",
      };
    }
  }

  ///Bulk product upload
  Future<String?> uploadBulkProductList(File excelFile) async {
    final url = Uri.parse('$baseUrlProduct$bulkProductAPI'); // e.g., http://.../api/product/upload

    try {
      final request = http.MultipartRequest('POST', url);

      // Add the Excel file (adjust 'file' if backend uses another field name)
      request.files.add(await http.MultipartFile.fromPath('file', excelFile.path));

      // Optional headers (don't manually set Content-Type)
      request.headers.addAll({
        "Accept": "application/json",
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = response.body;
        return data;
      } else {
        return "Failed to upload products: ${response.body}";
      }
    } catch (e) {
      return "Error uploading products: $e";
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