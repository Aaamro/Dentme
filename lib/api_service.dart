import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = 'http://localhost:3000'; // Replace with your backend URL

  // ---------- USER MANAGEMENT ----------
  Future<List<dynamic>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/users/allusers'),
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
      Uri.parse('$baseUrl/users/register'), // Updated endpoint
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
      Uri.parse('$baseUrl/users/edit/$id'),
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
      Uri.parse('$baseUrl/users/delete/$id'),
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
      Uri.parse('$baseUrl/users/login'),
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

  // ---------- PATIENT MANAGEMENT ----------
  Future<List<dynamic>> getPatients() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/patients/allpatients'),
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

  Future<Map<String, dynamic>> getPatient(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/patients/getpatient/$id'),
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

  Future<void> addPatient(String name, String contact, String medicalHistory) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/patients/register'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Current-Role': prefs.getString('role')!,
      },
      body: json.encode({
        'name': name,
        'contact': contact,
        'medical_history': medicalHistory,
      }),
    );

    if (response.statusCode != 201) {
      final error = json.decode(response.body)['error'];
      throw Exception(error);
    }
  }

  Future<void> editPatient(int id, {String? name, String? contact, String? medicalHistory}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/patients/edit/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Current-Role': prefs.getString('role')!,
      },
      body: json.encode({
        'name': name,
        'contact': contact,
        'medical_history': medicalHistory,
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body)['error'];
      throw Exception(error);
    }
  }

  Future<void> deletePatient(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/patients/delete/$id'),
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

  // ---------- APPOINTMENT MANAGEMENT ----------
  Future<List<dynamic>> getAppointmentsForPatient(int patientId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/appointments/getappointmentP/$patientId'),
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


  Future<List<dynamic>> getAppointmentsForDay(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/appointments/getappointmentsD?date=$date'),
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

  Future<void> addAppointment(int patientId, String date, String description) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/appointments/register'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Current-Role': prefs.getString('role')!,
      },
      body: json.encode({
        'patient_id': patientId,
        'date': date,
        'description': description,
      }),
    );

    if (response.statusCode != 201) {
      final error = json.decode(response.body)['error'];
      throw Exception(error);
    }
  }

  Future<void> editAppointment(int id, String date, String description) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/appointments/edit/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Current-Role': prefs.getString('role')!,
      },
      body: json.encode({
        'date': date,
        'description': description,
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body)['error'];
      throw Exception(error);
    }
  }

  Future<void> deleteAppointment(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/appointments/delete/$id'),
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

  // ---------- TEETH WORK MANAGEMENT ----------
  Future<List<dynamic>> getTeethWork(int patientId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/patients/$patientId/teeth'),
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

  Future<void> updateToothWork(int patientId, int toothNumber, String status, String notes) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/patients/$patientId/teeth/$toothNumber'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Current-Role': prefs.getString('role')!,
      },
      body: json.encode({
        'status': status,
        'notes': notes,
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body)['error'];
      throw Exception(error);
    }
  }
}
