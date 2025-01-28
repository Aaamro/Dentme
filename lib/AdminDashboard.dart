import 'package:dentme_v1/SimpleTeethDiagram.dart';
import 'package:dentme_v1/TeethDiagram.dart';
import 'package:flutter/material.dart';
import 'CreateUserDialog.dart';
import 'EditUserDialog.dart';
import 'api_service.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _selectedPage = 'Manage Users';

  // Define Admin-specific menu options
  final List<String> _menuOptions = [
    'Home',
    'Manage Users',
    'Reports',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    if (_selectedPage == 'Manage Users') {
      _fetchUsers();
    }
  }

  // Fetch users from the API
  void _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _apiService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show Create User dialog
  void _createUser() {
    showDialog(
      context: context,
      builder: (context) => CreateUserDialog(onSuccess: _fetchUsers),
    );
  }

  // Show Edit User dialog
  void _editUser(int userId, String currentEmail, String currentRole) {
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(
        userId: userId,
        currentEmail: currentEmail,
        currentRole: currentRole,
        onSuccess: _fetchUsers,
      ),
    );
  }

  // Delete a user
  void _deleteUser(int userId) async {
    try {
      await _apiService.deleteUser(userId);
      _fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Row(
        children: [
          // Navigation Pane
          NavigationBar(
            menuOptions: _menuOptions,
            onSelectPage: (page) {
              setState(() {
                _selectedPage = page;

                // Fetch users if "Manage Users" is selected
                if (page == 'Manage Users') {
                  _fetchUsers();
                }
              });
            },
          ),

          // Content Area
          Expanded(
            child: AdminContentArea(
              selectedPage: _selectedPage,
              users: _users,
              isLoading: _isLoading,
              createUser: _createUser,
              editUser: _editUser,
              deleteUser: _deleteUser,
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationBar extends StatelessWidget {
  final List<String> menuOptions;
  final Function(String) onSelectPage;

  NavigationBar({required this.menuOptions, required this.onSelectPage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.blueGrey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation Bar Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Admin Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(color: Colors.white54),
          // Navigation Items
          ...menuOptions.map((option) {
            return ListTile(
              title: Text(
                option,
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => onSelectPage(option),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class AdminContentArea extends StatelessWidget {
  final String selectedPage;
  final List<dynamic> users;
  final bool isLoading;
  final VoidCallback createUser;
  final Function(int, String, String) editUser;
  final Function(int) deleteUser;

  AdminContentArea({
    required this.selectedPage,
    required this.users,
    required this.isLoading,
    required this.createUser,
    required this.editUser,
    required this.deleteUser,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    switch (selectedPage) {
      case 'Manage Users':
        content = isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    title: Text(user['email']),
                    subtitle: Text('Role: ${user['role']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => editUser(
                              user['id'], user['email'], user['role']),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => deleteUser(user['id']),
                        ),
                      ],
                    ),
                  );
                },
              );
        break;
      case 'Reports':
        content = Center(child: SimpleTeethDiagramPage());
        break;  
      case 'Settings':
        content = Center(child: Text('Settings Page (Under Construction)'));
        break;
      default:
        content = Center(child: Text('Admin Home Page'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: content,
    );
  }
}
