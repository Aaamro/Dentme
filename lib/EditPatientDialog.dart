import 'package:flutter/material.dart';
import 'api_service.dart';

class EditPatientDialog extends StatefulWidget {
  final int patientId;
  final String currentName;
  final String currentContact;
  final String currentMedicalHistory;
  final VoidCallback onSuccess;

  EditPatientDialog({
    required this.patientId,
    required this.currentName,
    required this.currentContact,
    required this.currentMedicalHistory,
    required this.onSuccess,
  });

  @override
  _EditPatientDialogState createState() => _EditPatientDialogState();
}

class _EditPatientDialogState extends State<EditPatientDialog> {
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _medicalHistoryController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _contactController = TextEditingController(text: widget.currentContact);
    _medicalHistoryController =
        TextEditingController(text: widget.currentMedicalHistory);
  }

  void _editPatient() async {
    final name = _nameController.text;
    final contact = _contactController.text;
    final medicalHistory = _medicalHistoryController.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name is required')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService().editPatient(
        widget.patientId,
        name: name,
        contact: contact,
        medicalHistory: medicalHistory,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Patient updated successfully')),
      );
      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update patient: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Patient'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _contactController,
              decoration: InputDecoration(labelText: 'Contact'),
            ),
            TextField(
              controller: _medicalHistoryController,
              decoration: InputDecoration(labelText: 'Medical History'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        _isLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _editPatient,
                child: Text('Save Changes'),
              ),
      ],
    );
  }
}
