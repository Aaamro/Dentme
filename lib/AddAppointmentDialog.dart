import 'package:flutter/material.dart';
import 'api_service.dart';

class AddAppointmentDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  AddAppointmentDialog({required this.onSuccess});

  @override
  _AddAppointmentDialogState createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<AddAppointmentDialog> {
  final _patientIdController = TextEditingController();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  void _addAppointment() async {
    final patientId = int.tryParse(_patientIdController.text);
    final date = _dateController.text;
    final description = _descriptionController.text;

    if (patientId == null || date.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService().addAppointment(patientId, date, description);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment added successfully')),
      );
      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add appointment: $e')),
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
      title: Text('Add Appointment'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _patientIdController,
              decoration: InputDecoration(labelText: 'Patient ID'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _dateController,
              decoration: InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
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
                onPressed: _addAppointment,
                child: Text('Add'),
              ),
      ],
    );
  }
}
