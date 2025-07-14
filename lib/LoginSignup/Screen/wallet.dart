import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:budgettrack/LoginSignup/Screen/notification.dart';

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late FirebaseAuth _auth;
  late FirebaseDatabase _database;
  late User? _user;
  double _balance = 0.0;
  double _goalAmount = 5000.0;
  double _progress = 0.0;
  double _sliderValue = 5000.0; // Default goal value
  TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _database = FirebaseDatabase.instance;
    _user = _auth.currentUser;

    if (_user != null) {
      _loadWalletData();  // Load wallet data when the screen initializes
    }
  }

  // Fetch the wallet data from Firebase
  void _loadWalletData() async {
    if (_user == null) return;

    DatabaseReference userRef = _database.ref('users/${_user?.uid}/wallet');
    DatabaseEvent event = await userRef.once();

    if (event.snapshot.exists) {
      final Map<dynamic, dynamic> walletData = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        _balance = walletData['balance']?.toDouble() ?? 0.0; // Explicit conversion to double
        _goalAmount = walletData['goal']?.toDouble() ?? 5000.0; // Explicit conversion to double
        _progress = (_balance / _goalAmount);
        _sliderValue = _goalAmount; // Set the slider to current goal value
      });
    } else {
      setState(() {
        _balance = 0.0;
        _goalAmount = 5000.0;  // Default goal if no data
        _progress = (_balance / _goalAmount); // Set progress to 0 initially
        _sliderValue = _goalAmount;  // Set slider to goal amount
      });
    }
  }

  // Update the wallet balance and progress in Firebase
  void _updateBalance() {
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount > 0) {
      setState(() {
        _balance += amount;  // Update balance
        _progress = (_balance / _goalAmount);  // Update progress based on new balance
      });

      // Update balance in Firebase
      DatabaseReference userRef = _database.ref('users/${_user?.uid}/wallet');
      userRef.update({'balance': _balance});
    } else {
      // Show an error message if the amount is invalid
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount')),
      );
    }
  }

  // Set the savings goal in Firebase
  void _setGoal() {
    setState(() {
      _goalAmount = _sliderValue;
      _progress = (_balance / _goalAmount);  // Update progress based on new goal
    });

    // Save the new goal to Firebase
    DatabaseReference userRef = _database.ref('users/${_user?.uid}/wallet');
    userRef.update({'goal': _goalAmount});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1FF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Wallet',
                style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
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
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _database.ref('users/${_user?.uid}/wallet').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data != null) {
            var walletData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
            if (walletData != null) {
              double newBalance = walletData['balance']?.toDouble() ?? 0.0;
              double newGoal = walletData['goal']?.toDouble() ?? 5000.0;

              if (newBalance != _balance || newGoal != _goalAmount) {
                setState(() {
                  _balance = newBalance;
                  _goalAmount = newGoal;
                  _progress = (_balance / _goalAmount);

                  if ((_sliderValue - _goalAmount).abs() > 1.0) {
                    _sliderValue = _goalAmount;
                  }
                });
              }
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wallet Card Section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade500, Colors.red.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VISA',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'RM ${_balance.toStringAsFixed(2)}', // Display current balance dynamically
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Goal: RM${_goalAmount.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _progress,
                        minHeight: 5,
                        color: Colors.white,
                        backgroundColor: Colors.white24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Progress: ${( (_progress) * 100).toStringAsFixed(0)}%',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),

                // Goal Slider Section (Now independent of Firebase)
                Text('Set your savings goal:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        offset: Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: Colors.red, // Color of the active part of the track
                          inactiveTrackColor: Colors.white, // Color of the inactive part of the track
                          thumbColor: Colors.red, // Color of the thumb (the circle)
                          overlayColor: Colors.red.withOpacity(0.2), // Color of the overlay (when the thumb is pressed)
                          trackHeight: 4.0, // Height of the track
                        ),
                        child: Slider(
                          value: _sliderValue,
                          min: 0.0,
                          max: 100000.0,
                          divisions: 100,
                          label: 'RM ${_sliderValue.toStringAsFixed(2)}',
                          onChanged: (double value) {
                            setState(() {
                              _sliderValue = value;
                            });
                          },
                        ),
                      ),
                      Text(
                        'Set Goal: RM ${_sliderValue.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      // Add Goal Button
                      ElevatedButton(
                        onPressed: _setGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange.shade700, Colors.yellow.shade400],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            alignment: Alignment.center,
                            child: Text(
                              'Set Goal',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 50),

                // Amount Input Field
                Text('Enter amount to add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        offset: Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _amountController, // Ensure the controller is added
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // Add Money Button
                ElevatedButton(
                  onPressed: _updateBalance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade700, Colors.yellow.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      alignment: Alignment.center,
                      child: Text(
                        'Add Money',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
