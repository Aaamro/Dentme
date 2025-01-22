import 'package:flutter/material.dart';
import 'api_service.dart';

class EditUserDialog extends StatefulWidget {
  final int userId;
  final String currentEmail;
  final String currentRole;
  final VoidCallback onSuccess;

  EditUserDialog({
    required this.userId,
    required this.currentEmail,
    required this.currentRole,
    required this.onSuccess,
  });

  @override
  _EditUserDialogState createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late TextEditingController _emailController;
  String _selectedRole = '';
  bool _isLoading = false;

  final List<String> _roles = ['Admin', 'Secretary', 'Doctor'];

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.currentEmail);
    _selectedRole = widget.currentRole;
  }

  void _editUser() async {
    final email = _emailController.text;
    final role = _selectedRole;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email cannot be empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService().editUser(widget.userId, email: email, role: role);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User updated successfully')),
      );
      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
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
      title: Text('Edit User'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            DropdownButton<String>(
              value: _selectedRole,
              items: _roles
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
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
                onPressed: _editUser,
                child: Text('Save Changes'),
              ),
      ],
    );
  }
}
