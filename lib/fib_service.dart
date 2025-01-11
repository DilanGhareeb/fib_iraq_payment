import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

// Define an enum for mode
enum Mode { stage, dev, prod }

class FIBService {
  // Private constructor
  FIBService._internal({
    required this.clientId,
    required this.clientSecret,
    required this.mode,
  });

  // Static instance (nullable for lazy initialization)
  static FIBService? _instance;

  // Public factory for initialization and access
  static FIBService initialize({
    required String clientId,
    required String clientSecret,
    required Mode mode,
  }) {
    if (_instance != null) {
      throw Exception('FIBService has already been initialized.');
    }
    _instance = FIBService._internal(
      clientId: clientId,
      clientSecret: clientSecret,
      mode: mode,
    );
    return _instance!;
  }

  // Access the already-initialized instance
  static FIBService get instance {
    if (_instance == null) {
      throw Exception(
          'FIBService has not been initialized. Call initialize() first.');
    }
    return _instance!;
  }

  final Dio _dio = Dio();
  final String clientId;
  final String clientSecret;
  final Mode mode;

  // Convert mode to string for URLs
  String get _modeString {
    switch (mode) {
      case Mode.stage:
        return 'stage';
      case Mode.dev:
        return 'dev';
      case Mode.prod:
        return 'prod';
    }
  }

  String get _authUrl =>
      'https://fib.$_modeString.fib.iq/auth/realms/fib-online-shop/protocol/openid-connect/token';
  String get _paymentUrl =>
      'https://fib.$_modeString.fib.iq/protected/v1/payments';

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
