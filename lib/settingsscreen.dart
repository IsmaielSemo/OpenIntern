import 'package:flutter/material.dart';
import 'editprofilescreen.dart';
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF4285F4),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF4285F4),
              child: Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
            title: const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: const Text('Update your personal information'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF4285F4),
              child: Icon(
                Icons.notifications,
                color: Colors.white,
              ),
            ),
            title: const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: const Text('Manage notification preferences'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to notifications settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF4285F4),
              child: Icon(
                Icons.privacy_tip,
                color: Colors.white,
              ),
            ),
            title: const Text(
              'Privacy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: const Text('Manage privacy settings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to privacy settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(
                Icons.logout,
                color: Colors.white,
              ),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Perform logout
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
