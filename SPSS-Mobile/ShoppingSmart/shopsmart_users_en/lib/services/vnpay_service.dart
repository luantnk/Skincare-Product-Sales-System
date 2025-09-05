import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/api_response_model.dart';
import 'jwt_service.dart';

class VNPayService {
  static const String baseUrl = 'https://spssapi-hxfzbchrcafgd2hg.southeastasia-01.azurewebsites.net';
  static const String apiUrl = 'https://spssapi-hxfzbchrcafgd2hg.southeastasia-01.azurewebsites.net';
  static const String nGrokUrl = 'https://spssapi-hxfzbchrcafgd2hg.southeastasia-01.azurewebsites.net';

  static const Duration timeout = Duration(seconds: 30);

  /// Get VNPay transaction status and payment URL
  static Future<ApiResponse<String>> getVNPayTransactionStatus({
    required String orderId,
    required String userId,
    String? urlReturn,
  }) async {
    print('DEBUG VNPayService: Getting VNPay transaction status for order: $orderId, user: $userId');
    try {
      final token = await JwtService.getStoredToken();
      if (token == null) {
        print('DEBUG VNPayService: No authentication token found');
        return ApiResponse<String>(
          success: false,
          message: 'User not authenticated',
          errors: ['No authentication token found'],
        );
      }

      // Encode the return URL
      final encodedUrlReturn = urlReturn ?? nGrokUrl;
      final encodedUrl = Uri.encodeComponent(encodedUrlReturn);

      final uri = Uri.parse(
        '$baseUrl/api/VNPAY/get-transaction-status-vnpay?orderId=$orderId&userId=$userId&urlReturn=$encodedUrl',
      );

      print('DEBUG VNPayService: Calling API: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(timeout);

      print('DEBUG VNPayService: API response status: ${response.statusCode}');
      print('DEBUG VNPayService: API response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          print('DEBUG VNPayService: Successfully got VNPay URL: ${jsonData['data']}');
          return ApiResponse<String>(
            success: true,
            data: jsonData['data'],
            message:
                jsonData['message'] ??
                'VNPay payment URL generated successfully',
          );
        } else {
          print('DEBUG VNPayService: Failed to get VNPay URL: ${jsonData['message']}');
          return ApiResponse<String>(
            success: false,
            message:
                jsonData['message'] ?? 'Failed to generate VNPay payment URL',
          );
        }
      } else {
        print('DEBUG VNPayService: API call failed with status: ${response.statusCode}');
        return ApiResponse<String>(
          success: false,
          message:
              'Failed to generate VNPay payment URL. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('DEBUG VNPayService: Error generating VNPay payment URL: $e');
      return ApiResponse<String>(
        success: false,
        message: 'Error generating VNPay payment URL: ${e.toString()}',
        errors: [e.toString()],
      );
    }
  }

  /// Launch VNPay payment URL
  static Future<bool> launchVNPayPayment(String paymentUrl) async {
    try {
      final uri = Uri.parse(paymentUrl);

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch VNPay payment URL');
      }
    } catch (e) {
      print('Error launching VNPay payment: $e');
      return false;
    }
  }

  /// Process VNPay payment for an order
  static Future<ApiResponse<String>> processVNPayPayment({
    required String orderId,
    required String userId,
  }) async {
    try {
      // Get VNPay payment URL
      final response = await getVNPayTransactionStatus(
        orderId: orderId,
        userId: userId,
      );

      if (response.success && response.data != null) {
        // Launch VNPay payment
        final launched = await launchVNPayPayment(response.data!);

        if (launched) {
          return ApiResponse<String>(
            success: true,
            data: response.data,
            message: 'VNPay payment launched successfully',
          );
        } else {
          return ApiResponse<String>(
            success: false,
            message: 'Failed to launch VNPay payment',
          );
        }
      } else {
        return response;
      }
    } catch (e) {
      return ApiResponse<String>(
        success: false,
        message: 'Error processing VNPay payment: ${e.toString()}',
        errors: [e.toString()],
      );
    }
  }

  /// Process VNPay payment for existing order (for retry payment)
  static Future<ApiResponse<String>> processVNPayPaymentForExistingOrder({
    required String orderId,
  }) async {
    try {
      // Get user ID from token
      final token = await JwtService.getStoredToken();
      if (token == null) {
        return ApiResponse<String>(
          success: false,
          message: 'User not authenticated',
          errors: ['No authentication token found'],
        );
      }

      final userInfo = JwtService.getUserFromToken(token);
      final userId = userInfo?['id'] ?? '';

      if (userId.isEmpty) {
        return ApiResponse<String>(
          success: false,
          message: 'Could not determine user information',
          errors: ['User ID not found in token'],
        );
      }

      // Process VNPay payment
      return await processVNPayPayment(orderId: orderId, userId: userId);
    } catch (e) {
      return ApiResponse<String>(
        success: false,
        message:
            'Error processing VNPay payment for existing order: ${e.toString()}',
        errors: [e.toString()],
      );
    }
  }

  /// Check if payment method is VNPay
  static bool isVNPayPayment(String paymentType) {
    print('DEBUG VNPayService: Checking payment type: "$paymentType"');
    final isVNPay = paymentType.toUpperCase() == 'VNPAY';
    print('DEBUG VNPayService: Is VNPay payment: $isVNPay');
    return isVNPay;
  }
}
