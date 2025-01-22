import 'package:flutter/material.dart';
import 'api_service.dart';

class DashboardScreen extends StatefulWidget {
  final String role;

  DashboardScreen({required this.role});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedPage = 'Home';

  // Define menu options for each role
  final Map<String, List<String>> roleMenus = {
    'Admin': ['Home', 'Manage Users', 'Reports'],
    'Secretary': ['Home', 'Appointments', 'Patients'],
    'Doctor': ['Home', 'My Schedule', 'Patient Records'],
  };

  @override
  Widget build(BuildContext context) {
    final menuOptions = roleMenus[widget.role] ?? ['Home'];

    return Scaffold(
      body: Row(
        children: [
          // Navigation Pane
          NavigationPane(
            menuOptions: menuOptions,
            onSelectPage: (page) {
              setState(() {
                _selectedPage = page;
              });
            },
          ),

          // Content Area
          Expanded(
            child: ContentArea(page: _selectedPage),
          ),
        ],
      ),
    );
  }
}

class NavigationPane extends StatelessWidget {
  final List<String> menuOptions;
  final Function(String) onSelectPage;

  NavigationPane({required this.menuOptions, required this.onSelectPage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Colors.blueGrey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          Divider(color: Colors.white54),
          ...menuOptions.map((option) {
            return ListTile(
              title: Text(option, style: TextStyle(color: Colors.white)),
              onTap: () => onSelectPage(option),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class ContentArea extends StatelessWidget {
  final String page;

  ContentArea({required this.page});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'You selected: $page',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
