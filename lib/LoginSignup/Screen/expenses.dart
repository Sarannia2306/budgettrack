import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:budgettrack/LoginSignup/Screen/add_income.dart';
import 'package:budgettrack/LoginSignup/Screen/add_expense.dart';

class ExpensesScreen extends StatefulWidget {
  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseDatabase _database = FirebaseDatabase.instance;
  User? _user;
  bool _isNewUser = false;
  List<Map<String, dynamic>> _incomeTransactions = [];
  List<Map<String, dynamic>> _expenseTransactions = [];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _loadTransactions();
    }
  }

  // Function to load both income and expense transactions
  void _loadTransactions() async {
    DatabaseReference userRef = _database.ref('users/${_user?.uid}');

    // Fetch income transactions
    DatabaseEvent incomeEvent = await userRef.child('transactions/income').once();
    if (incomeEvent.snapshot.exists) {
      final List<Map<String, dynamic>> incomeList = [];
      Map<dynamic, dynamic> incomeData = incomeEvent.snapshot.value as Map<dynamic, dynamic>;
      incomeData.forEach((key, value) {
        incomeList.add(Map<String, dynamic>.from(value));
      });
      setState(() {
        _incomeTransactions = incomeList;
      });
    }

    // Fetch expense transactions
    DatabaseEvent expenseEvent = await userRef.child('transactions/expenses').once();
    if (expenseEvent.snapshot.exists) {
      final List<Map<String, dynamic>> expenseList = [];
      Map<dynamic, dynamic> expenseData = expenseEvent.snapshot.value as Map<dynamic, dynamic>;
      expenseData.forEach((key, value) {
        expenseList.add(Map<String, dynamic>.from(value));
      });
      setState(() {
        _expenseTransactions = expenseList;
      });
    }
  }

  // Handle Bottom Navigation bar tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Navigate to AddIncomeScreen
  void _navigateToAddIncomeScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddIncomeScreen()),
    ).then((_) {
      _loadTransactions(); // Refresh after returning
    });
  }

  // Navigate to AddExpenseScreen
  void _navigateToAddExpenseScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddExpenseScreen()),
    ).then((_) {
      _loadTransactions();
    });
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
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Add',
                style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black), // Back arrow icon
            onPressed: () {
              Navigator.pop(context); // Navigate back to the previous screen
            },
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton('Add Income', Colors.orange.shade700, Icons.wallet, _navigateToAddIncomeScreen),
                _buildActionButton('Add Expense', Colors.red.shade700, Icons.money_off, _navigateToAddExpenseScreen),
              ],
            ),

            SizedBox(height: 20),
            // Last Added Section
            Text('Last Added', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView(
                children: [
                  if (_incomeTransactions.isNotEmpty || _expenseTransactions.isNotEmpty) ...[
                    // Display Income Transactions
                    if (_incomeTransactions.isNotEmpty) ...[
                      ..._incomeTransactions.map((transaction) {
                        return _buildTransactionItem(
                          transaction['title'],
                          transaction['amount'],
                          transaction['time'],
                          'income', // Type is 'income' for income transactions
                        );
                      }).toList(),
                    ],
                    SizedBox(height: 10),
                    // Display Expense Transactions
                    if (_expenseTransactions.isNotEmpty) ...[
                      ..._expenseTransactions.map((transaction) {
                        return _buildTransactionItem(
                          transaction['title'],
                          transaction['amount'],
                          transaction['time'],
                          'expense', // Type is 'expense' for expense transactions
                        );
                      }).toList(),
                    ],
                  ] else
                    Center(
                      child: Text(
                        'No transactions yet!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build Add Income/Add Expense Buttons with Gradient and Shadow
  Widget _buildActionButton(String text, Color gradientStart, IconData icon, Function() onPressed) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8),
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientStart, gradientStart.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(4, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 30),
              SizedBox(height: 10),
              Text(
                text,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build transaction items with "+" or "-" sign for the amount
  Widget _buildTransactionItem(String title, dynamic amount, String time, String type) {
    String sign = type == 'income' ? '+' : '-';
    Color amountColor = type == 'income' ? Colors.green : Colors.red;

    double parsedAmount = amount is int ? amount.toDouble() : amount;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.white60,
          child: Icon(
            type == 'expense' ? Icons.money_off : Icons.wallet,
            color: type == 'income' ? Colors.orange.shade500 : Colors.red,
          ),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(time),
        trailing: Text(
          '$sign\RM${parsedAmount.toStringAsFixed(2)}',
          style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
