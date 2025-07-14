import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:budgettrack/LoginSignup/Screen/edit_profile.dart';
import 'package:budgettrack/LoginSignup/Screen/privacy_policy.dart';
import 'package:budgettrack/LoginSignup/Screen/login.dart';
import 'package:budgettrack/LoginSignup/Screen/notification.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = '';
  String email = '';
  double income = 0.00;
  double expenses = 0.00;

  int _selectedIndex = 0;

  // Function to handle Bottom Navigation Bar selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchUserDetails(); // Get user details from Firebase
  }

  // Fetch user details from Firebase Realtime Database
  void fetchUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DatabaseReference userRef = FirebaseDatabase.instance.ref("users/${user.uid}");

      // Get user data from Realtime Database
      final snapshot = await userRef.get();

      if (snapshot.exists) {
        setState(() {
          username = snapshot.child('name').value.toString(); // Cast to String
          email = snapshot.child('email').value.toString(); // Cast to String
          income = double.tryParse(snapshot.child('transactions/income').value.toString()) ?? 0.00; // Cast to double
          expenses = double.tryParse(snapshot.child('transactions/expenses').value.toString()) ?? 0.00; // Cast to double
        });
      }
    }
  }

  // Handle menu item tap (navigate to respective screens)
  void navigateToScreen(String screenName) {
    switch (screenName) {
      case 'Account Info':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditProfileScreen()),
        );
        break;
      case 'Privacy Policy':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
        );
        break;
      case 'Logout':
        FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1FF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Center(
            child: Text(
              'Profile',
              style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications, color: Colors.black),
              onPressed: () {
                // Navigate to the NotificationScreen when the icon is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationScreen()),
                );
              }
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo Section
            Image.asset(
              'assets/images/app_logo.png',
              height: 200,
              width: 300,
            ),
            SizedBox(height: 12),
            Text(
              username,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              email,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            SizedBox(height: 30),

            // Settings Menu Section
            _buildMenuItem('Account Info', Icons.account_circle),
            _buildMenuItem('Privacy Policy', Icons.lock, color: Colors.grey),
            _buildMenuItem('Logout', Icons.logout, color: Colors.red),
          ],
        ),
      ),
    );
  }


  // Function to create the menu items
  Widget _buildMenuItem(String title, IconData icon, {Color color = Colors.blue}) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 12),
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.black),
      onTap: () {
        navigateToScreen(title); // Handle menu item tap action
      },
    );
  }
}
