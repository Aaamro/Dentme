import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = 'http://localhost:3000'; // Replace with your backend URL

Future<List<dynamic>> getUsers() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.get(
    Uri.parse('$baseUrl/users'),
    headers: {
      'Authorization': 'Bearer $token',
      'Current-Role': prefs.getString('role')!,
    },
    
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    final error = json.decode(response.body)['error'];
    throw Exception(error);
  }
}

Future<void> createUser(String email, String password, String role) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.post(
    Uri.parse('$baseUrl/register'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Current-Role': prefs.getString('role')!,
    },
    body: json.encode({'email': email, 'password': password, 'role': role}),
  );

  if (response.statusCode != 201) {
    final error = json.decode(response.body)['error'];
    throw Exception(error);
  }
}

Future<void> editUser(int id, {String? email, String? role}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.put(
    Uri.parse('$baseUrl/users/$id'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Current-Role': prefs.getString('role')!,
    },
    body: json.encode({'email': email, 'role': role}),
  );

  if (response.statusCode != 200) {
    final error = json.decode(response.body)['error'];
    throw Exception(error);
  }
}

Future<void> deleteUser(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.delete(
    Uri.parse('$baseUrl/users/$id'),
    headers: {
      'Authorization': 'Bearer $token',
      'Current-Role': prefs.getString('role')!,
      },
  );

  if (response.statusCode != 200) {
    final error = json.decode(response.body)['error'];
    throw Exception(error);
  }
}

Future<Map<String, dynamic>> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/login'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'email': email, 'password': password}),
  );

  if (response.statusCode == 200) {
    final responseData = json.decode(response.body);
    final token = responseData['token'];
    final role = responseData['role'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('role', role);

    return {'token': token, 'role': role};
  } else {
    final error = json.decode(response.body)['error'];
    throw Exception(error);
  }
}


  Future<List<dynamic>> getPatients() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/patients'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch patients');
    }
  }

  Future<void> addPatient(String name, String contact, String medicalHistory) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/patients'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'name': name,
        'contact': contact,
        'medical_history': medicalHistory,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add patient');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
