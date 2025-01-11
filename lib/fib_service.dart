import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

class FIBService {
  // Step 1: Create a private constructor
  FIBService._internal();

  // Step 2: Create a static instance
  static final FIBService _instance = FIBService._internal();

  // Step 3: Provide a factory constructor to return the single instance
  factory FIBService() => _instance;

  final Dio _dio = Dio();
  String clientId = '';
  String clientSecret = '';
  String mode = 'stage'; // stage - dev - prod or any other mode

  String get _authUrl =>
      'https://fib.$mode.fib.iq/auth/realms/fib-online-shop/protocol/openid-connect/token';
  String get _paymentUrl => 'https://fib.$mode.fib.iq/protected/v1/payments';

  Future<String> _getAccessToken() async {
    final response = await _dio.post(
      _authUrl,
      data: {
        'grant_type': 'client_credentials',
        'client_id': clientId,
        'client_secret': clientSecret,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    return response.data['access_token'];
  }

  Future<Map<String, dynamic>> createPayment(
      int amount, String description, String statusCallbackUrl) async {
    final token = await _getAccessToken();
    final response = await _dio.post(
      _paymentUrl,
      data: {
        'monetaryValue': {
          'amount': amount.toString(),
          'currency': 'IQD',
        },
        'statusCallbackUrl': statusCallbackUrl,
        'description': description,
        'expiresIn': 'PT12H',
        'refundableFor': '',
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
    final token = await _getAccessToken();
    final url = '$_paymentUrl/$paymentId/status';

    final response = await _dio.get(
      url,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return response.data;
  }

  Uint8List base64ToImage(String base64String) {
    return base64Decode(base64String);
  }

  Future<Map<String, dynamic>> refundPayment(String paymentId) async {
    final token = await _getAccessToken();
    final url = '$_paymentUrl/$paymentId/refund';

    final response = await _dio.post(
      url,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return response.data;
  }
}
