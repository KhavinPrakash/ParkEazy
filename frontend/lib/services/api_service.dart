import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/slot_model.dart';
import '../models/reservation_model.dart';
import '../models/sms_model.dart';
import '../models/facility_model.dart';

class ApiService {
  static const String defaultLocalIp = "http://172.20.10.12:8000";
  static String? _customUrl;
  static final http.Client _client = http.Client();

  static String get baseUrl {
    if (_customUrl != null && _customUrl!.isNotEmpty) {
      return _customUrl!;
    }
    if (kIsWeb) {
      try {
        final host = Uri.base.host;
        if (host.isNotEmpty && host != "localhost" && host != "127.0.0.1") {
          return "http://$host:8000";
        }
      } catch (_) {}
    }
    return defaultLocalIp;
  }

  static String? _token;
  static UserModel? _currentUser;
  static SharedPreferences? _prefs;

  static UserModel? get currentUser => _currentUser;
  static String? get token => _token;

  static Future<void> init() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      _token = _prefs?.getString('auth_token');
      _customUrl = _prefs?.getString('custom_server_url');
      final userStr = _prefs?.getString('user_data');
      if (userStr != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userStr));
      }
    } catch (_) {}
  }

  static Future<void> setCustomServerUrl(String url) async {
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith("http://") && !formattedUrl.startsWith("https://")) {
      formattedUrl = "http://$formattedUrl";
    }
    if (formattedUrl.endsWith("/")) {
      formattedUrl = formattedUrl.substring(0, formattedUrl.length - 1);
    }
    _customUrl = formattedUrl;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString('custom_server_url', formattedUrl);
  }

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Connection': 'close',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Auth Methods
  static Future<UserModel> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    String? vehicleNumber,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'phone_number': phoneNumber,
          'password': password,
          'vehicle_number': vehicleNumber,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access_token'];
        _currentUser = UserModel.fromJson(data['user']);

        _prefs ??= await SharedPreferences.getInstance();
        await _prefs?.setString('auth_token', _token!);
        await _prefs?.setString('user_data', jsonEncode(data['user']));
        return _currentUser!;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e.toString().contains("SocketException") || e.toString().contains("TimeoutException") || e.toString().contains("ClientException")) {
        throw Exception("Network Timeout to $baseUrl.\nEnsure phone is on same Wi-Fi and host IP is set to 172.20.10.12:8000.");
      }
      rethrow;
    }
  }

  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access_token'];
        _currentUser = UserModel.fromJson(data['user']);

        _prefs ??= await SharedPreferences.getInstance();
        await _prefs?.setString('auth_token', _token!);
        await _prefs?.setString('user_data', jsonEncode(data['user']));
        return _currentUser!;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Login failed. Please check your credentials.');
      }
    } catch (e) {
      if (e.toString().contains("SocketException") || e.toString().contains("TimeoutException") || e.toString().contains("ClientException")) {
        throw Exception("Connection Timed Out to server ($baseUrl).\nEnsure phone is on same Wi-Fi network (172.20.10.12:8000).");
      }
      rethrow;
    }
  }

  static Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove('auth_token');
    await _prefs?.remove('user_data');
  }

  // Multi-Facility Marketplace Methods
  static Future<List<FacilityModel>> getFacilities() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/facilities/'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((item) => FacilityModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load parking facilities');
      }
    } catch (e) {
      return [];
    }
  }

  static Future<List<FacilityModel>> searchFacilities(String query) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/facilities/search?q=${Uri.encodeComponent(query)}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((item) => FacilityModel.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<FacilityDetailModel> getFacilityDetail(int facilityId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/facilities/$facilityId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return FacilityDetailModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Server error (code ${response.statusCode})');
      }
    } catch (e) {
      if (e.toString().contains("SocketException") || e.toString().contains("TimeoutException") || e.toString().contains("ClientException")) {
        throw Exception("Connection timeout to $baseUrl. Check Wi-Fi connection and server status.");
      }
      rethrow;
    }
  }

  // Slots & Stats Methods
  static Future<List<ParkingSlotModel>> getParkingSlots() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/slots/'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((item) => ParkingSlotModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load parking slots');
      }
    } catch (e) {
      throw Exception('Network timeout fetching slots');
    }
  }

  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/slots/stats'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch dashboard stats');
      }
    } catch (e) {
      return {
        "total_slots": 10,
        "available_slots": 4,
        "occupied_slots": 4,
        "reserved_slots": 2,
        "occupancy_percentage": 60.0
      };
    }
  }

  // Reservation Methods
  static Future<ReservationModel> createReservation({
    required int slotId,
    required String vehicleNumber,
    required int hours,
    required String paymentMethod,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/reservations/'),
        headers: _headers,
        body: jsonEncode({
          'slot_id': slotId,
          'vehicle_number': vehicleNumber,
          'hours': hours,
          'payment_method': paymentMethod,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return ReservationModel.fromJson(jsonDecode(response.body));
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['detail'] ?? 'Failed to complete reservation');
      }
    } catch (e) {
      if (e.toString().contains("SocketException") || e.toString().contains("TimeoutException") || e.toString().contains("ClientException")) {
        throw Exception("Payment timeout. Ensure your mobile phone can reach $baseUrl on Wi-Fi.");
      }
      rethrow;
    }
  }

  static Future<List<ReservationModel>> getMyBookings() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/reservations/my-bookings'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((item) => ReservationModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (_) {
      return [];
    }
  }

  static Future<List<SMSLogModel>> getMySMSLogs() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/sms/my-sms'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((item) => SMSLogModel.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }
}