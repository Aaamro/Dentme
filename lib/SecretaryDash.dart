import 'package:dentme_v1/AddAppointmentDialog.dart';
import 'package:dentme_v1/AddPatientDialog.dart';
import 'package:dentme_v1/EditAppointmentDialog.dart';
import 'package:dentme_v1/EditPatientDialog.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

class SecretaryDashboard extends StatefulWidget {
  @override
  _SecretaryDashboardState createState() => _SecretaryDashboardState();
}

class _SecretaryDashboardState extends State<SecretaryDashboard> {
  String _selectedPage = 'Patients'; // Default selected page
  final ApiService _apiService = ApiService();
  List<dynamic> _patients = [];
  List<dynamic> _appointments = [];
  bool _isLoading = true;

  // Secretary-specific menu items
  final List<String> _menuItems = ['Patients', 'Appointments'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Fetch patients or appointments based on the selected page
  void _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedPage == 'Patients') {
        final patients = await _apiService.getPatients();
        setState(() {
          _patients = patients;
        });
      } else if (_selectedPage == 'Appointments') {
        // Replace with appropriate ID and date based on your logic
        final appointments = await _apiService.getAppointmentsForDay(DateTime.now().toString()); 
        setState(() {
          _appointments = appointments;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch $_selectedPage: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add a new patient
  void _addPatient() {
    showDialog(
      context: context,
      builder: (context) => AddPatientDialog(onSuccess: _fetchData),
    );
  }

  // Edit an existing patient
  void _editPatient(int patientId, String currentName, String currentContact, String currentMedicalHistory) {
    showDialog(
      context: context,
      builder: (context) => EditPatientDialog(
        patientId: patientId,
        currentName: currentName,
        currentContact: currentContact,
        currentMedicalHistory: currentMedicalHistory,
        onSuccess: _fetchData,
      ),
    );
  }

  // Add a new appointment
  void _addAppointment() {
    showDialog(
      context: context,
      builder: (context) => AddAppointmentDialog(onSuccess: _fetchData),
    );
  }

  // Edit an existing appointment
  void _editAppointment(int appointmentId, String currentDate, String currentDescription) {
    showDialog(
      context: context,
      builder: (context) => EditAppointmentDialog(
        appointmentId: appointmentId,
        currentDate: currentDate,
        currentDescription: currentDescription,
        onSuccess: _fetchData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Secretary Dashboard'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Row(
        children: [
          // Navigation Pane
          NavigationPane(
            menuItems: _menuItems,
            selectedPage: _selectedPage,
            onMenuSelect: (page) {
              setState(() {
                _selectedPage = page;
                _fetchData(); // Fetch data for the selected page
              });
            },
          ),

          // Content Area
          Expanded(
            child: ContentArea(
              selectedPage: _selectedPage,
              patients: _patients,
              appointments: _appointments,
              isLoading: _isLoading,
              onAddPatient: _addPatient,
              onEditPatient: _editPatient,
              onAddAppointment: _addAppointment,
              onEditAppointment: _editAppointment,
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationPane extends StatelessWidget {
  final List<String> menuItems;
  final String selectedPage;
  final Function(String) onMenuSelect;

  NavigationPane({
    required this.menuItems,
    required this.selectedPage,
    required this.onMenuSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.blueGrey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Secretary Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(color: Colors.white54),
          ...menuItems.map((item) {
            return ListTile(
              title: Text(
                item,
                style: TextStyle(
                  color: selectedPage == item ? Colors.white : Colors.white54,
                  fontWeight: selectedPage == item ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              tileColor: selectedPage == item ? Colors.blueGrey[700] : null,
              onTap: () => onMenuSelect(item),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class ContentArea extends StatelessWidget {
  final String selectedPage;
  final List<dynamic> patients;
  final List<dynamic> appointments;
  final bool isLoading;
  final VoidCallback onAddPatient;
  final Function(int, String, String, String) onEditPatient;
  final VoidCallback onAddAppointment;
  final Function(int, String, String) onEditAppointment;

  ContentArea({
    required this.selectedPage,
    required this.patients,
    required this.appointments,
    required this.isLoading,
    required this.onAddPatient,
    required this.onEditPatient,
    required this.onAddAppointment,
    required this.onEditAppointment,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (selectedPage == 'Patients') {
      return ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return ListTile(
            title: Text(patient['name']),
            subtitle: Text('Contact: ${patient['contact'] ?? 'N/A'}'),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => onEditPatient(
                patient['id'],
                patient['name'],
                patient['contact'],
                patient['medical_history'] ?? '',
              ),
            ),
          );
        },
      );
    } else if (selectedPage == 'Appointments') {
      return ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return ListTile(
            title: Text('Appointment on ${appointment['date']}'),
            subtitle: Text(appointment['description']),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => onEditAppointment(
                appointment['id'],
                appointment['date'],
                appointment['description'],
              ),
            ),
          );
        },
      );
    } else {
      return Center(child: Text('Invalid Page Selected'));
    }
  }
}
