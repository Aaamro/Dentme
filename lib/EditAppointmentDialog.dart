import 'package:flutter/material.dart';
import 'api_service.dart';

class EditAppointmentDialog extends StatefulWidget {
  final int appointmentId;
  final String currentDate;
  final String currentDescription;
  final VoidCallback onSuccess;

  EditAppointmentDialog({
    required this.appointmentId,
    required this.currentDate,
    required this.currentDescription,
    required this.onSuccess,
  });

  @override
  _EditAppointmentDialogState createState() => _EditAppointmentDialogState();
}

class _EditAppointmentDialogState extends State<EditAppointmentDialog> {
  late TextEditingController _dateController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.currentDate);
    _descriptionController = TextEditingController(text: widget.currentDescription);
  }

  void _editAppointment() async {
    final date = _dateController.text;
    final description = _descriptionController.text;

    if (date.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService().editAppointment(widget.appointmentId, date, description);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment updated successfully')),
      );
      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update appointment: $e')),
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
      title: Text('Edit Appointment'),
      content: SingleChildScrollView(
        child: Column(
          children: [
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
                onPressed: _editAppointment,
                child: Text('Save Changes'),
              ),
      ],
    );
  }
}
