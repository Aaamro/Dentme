import 'package:flutter/material.dart';
import 'api_service.dart';

class AddPatientDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  AddPatientDialog({required this.onSuccess});

  @override
  _AddPatientDialogState createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  bool _isLoading = false;

  void _addPatient() async {
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
      await ApiService().addPatient(name, contact, medicalHistory);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Patient added successfully')),
      );
      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add patient: $e')),
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
      title: Text('Add Patient'),
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
                onPressed: _addPatient,
                child: Text('Add'),
              ),
      ],
    );
  }
}
