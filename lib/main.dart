import 'package:budgettrack/LoginSignup/Screen/Overview.dart';
import 'package:budgettrack/LoginSignup/Screen/profile.dart';
import 'package:budgettrack/LoginSignup/Screen/wallet.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budgettrack/firebase_options.dart';
import 'package:budgettrack/LoginSignup/Screen/onboarding.dart';
import 'package:budgettrack/LoginSignup/Screen/login.dart';
import 'package:budgettrack/LoginSignup/Screen/home_screen.dart';
import 'package:budgettrack/LoginSignup/Screen/edit_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const BudgetPalApp());
}

class BudgetPalApp extends StatelessWidget {
  const BudgetPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(), // Stream to listen to authentication changes
        builder: (context, snapshot) {
          // If the user is logged in, navigate to the BottomNavScreen, else OnboardingPage or LoginPage
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); // Show loading spinner while waiting
          } else if (snapshot.hasData) {
            return BottomNavScreen(); // User is logged in, navigate to the main screen with BottomNav
          } else {
            return OnboardingPage(); // User is not logged in, navigate to Onboarding or Login
          }
        },
      ),
    );
  }
}

class BottomNavScreen extends StatefulWidget {
  @override
  _BottomNavScreenState createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _selectedIndex = 0;

  // List of screens for BottomNavigationBar
  final List<Widget> _screens = [
    HomeScreen(),
    WalletScreen(),
    OverviewScreen(),
    ProfileScreen(),
  ];

  // Function to handle Bottom Navigation Bar selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange.shade700,
        unselectedItemColor: Colors.grey.shade400,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
