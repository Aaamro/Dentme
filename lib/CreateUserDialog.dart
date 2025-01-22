import 'package:flutter/material.dart';
import 'api_service.dart';

class CreateUserDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  CreateUserDialog({required this.onSuccess});

  @override
  _CreateUserDialogState createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Secretary';
  bool _isLoading = false;

  final List<String> _roles = ['Admin', 'Secretary', 'Doctor'];

  void _createUser() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService().createUser(email, password, _selectedRole);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User created successfully')),
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
      title: Text('Create New User'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
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
                onPressed: _createUser,
                child: Text('Create'),
              ),
      ],
    );
  }
}
