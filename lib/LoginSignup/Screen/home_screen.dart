import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:budgettrack/LoginSignup/Screen/expenses.dart';
import 'package:budgettrack/LoginSignup/Screen/notification.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  double income = 0.00;
  double expenses = 0.00;
  double totalBalance = 0.00;

  String baseCurrency = 'MYR';
  String targetCurrency = 'USD';
  double amount = 1.0;
  double convertedAmount = 0.00;
  double exchangeRate = 0.0;
  List<String> currencies = ['MYR', 'USD', 'EUR', 'JPY', 'GBP'];

  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseDatabase _database = FirebaseDatabase.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _loadTransactions();
    }
    fetchCurrencies();
  }

  // Function to fetch the available currencies
  void fetchCurrencies() async {
    final url =
        'https://api.freecurrencyapi.com/v1/currencies?apikey=fca_live_VFYspIzra9L1XhlB0dfOfBAg7gknFDPB4Hu2fhqV';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        currencies = List<String>.from(data['data'].keys);
      });
    } else {
      throw Exception('Failed to load currencies');
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
        income = incomeList.fold(0.0, (sum, item) => sum + (item['amount'] ?? 0.0));
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
        expenses = expenseList.fold(0.0, (sum, item) => sum + (item['amount'] ?? 0.0));
        totalBalance = income - expenses; // Calculate the total balance
      });
    }
  }

  // Convert the currency
  void convertCurrency() async {
    final url =
        'https://api.freecurrencyapi.com/v1/latest?apikey=fca_live_VFYspIzra9L1XhlB0dfOfBAg7gknFDPB4Hu2fhqV';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        exchangeRate = data['data'][targetCurrency] / data['data'][baseCurrency];
        convertedAmount = amount * exchangeRate;
      });
    } else {
      throw Exception('Failed to load exchange rate');
    }
  }

  // Handle Bottom Navigation Bar selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color(0xFFF5F1FF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Dashboard',
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Balance Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade500, Colors.red.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'RM${totalBalance.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Income', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(
                            'RM${income.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.green.shade900, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Expenses', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(
                            'RM${expenses.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.red.shade900, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Currency Conversion Section
            SizedBox(height: 50),
            CurrencyConverterWidget(
              baseCurrency: baseCurrency,
              targetCurrency: targetCurrency,
              amount: amount,
              convertedAmount: convertedAmount,
              exchangeRate: exchangeRate,
              currencies: currencies,
              onBaseCurrencyChanged: (value) {
                setState(() {
                  baseCurrency = value!;
                  convertCurrency();
                });
              },
              onTargetCurrencyChanged: (value) {
                setState(() {
                  targetCurrency = value!;
                  convertCurrency();
                });
              },
              onAmountChanged: (value) {
                setState(() {
                  amount = double.parse(value);
                  convertCurrency();
                });
              },
            ),

            // Spacer to push content up
            Spacer(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExpensesScreen()),
          );
        },
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white, // Set the icon color to white
        child: Icon(Icons.add),
      ),
    );
  }
}

// CurrencyConverterWidget for Currency Conversion UI
class CurrencyConverterWidget extends StatelessWidget {
  final String baseCurrency;
  final String targetCurrency;
  final double amount;
  final double convertedAmount;
  final double exchangeRate;
  final List<String> currencies;
  final Function(String?) onBaseCurrencyChanged;
  final Function(String?) onTargetCurrencyChanged;
  final Function(String) onAmountChanged;

  CurrencyConverterWidget({
    required this.baseCurrency,
    required this.targetCurrency,
    required this.amount,
    required this.convertedAmount,
    required this.exchangeRate,
    required this.currencies,
    required this.onBaseCurrencyChanged,
    required this.onTargetCurrencyChanged,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Currency conversion title
          Text(
            'Currency Conversion',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),

          // Amount input field with enhanced style
          TextField(
            decoration: InputDecoration(
              labelText: 'Amount',
              labelStyle: TextStyle(color: Colors.orange),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            ),
            keyboardType: TextInputType.number,
            onChanged: onAmountChanged,
            controller: TextEditingController(text: amount.toString()),
          ),
          SizedBox(height: 16),

          // Dropdown for base currency with better UI
          DropdownButtonFormField<String>(
            value: baseCurrency,
            onChanged: onBaseCurrencyChanged,
            items: currencies
                .map((currency) => DropdownMenuItem(value: currency, child: Text(currency)))
                .toList(),
            decoration: InputDecoration(
              labelText: 'Base Currency',
              labelStyle: TextStyle(color: Colors.orange),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            ),
          ),
          SizedBox(height: 16),

          // Dropdown for target currency with better UI
          DropdownButtonFormField<String>(
            value: targetCurrency,
            onChanged: onTargetCurrencyChanged,
            items: currencies
                .map((currency) => DropdownMenuItem(value: currency, child: Text(currency)))
                .toList(),
            decoration: InputDecoration(
              labelText: 'Target Currency',
              labelStyle: TextStyle(color: Colors.orange),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            ),
          ),
          SizedBox(height: 16),

          // Result of the conversion with styling
          Text(
            'Converted Amount: ${convertedAmount.toStringAsFixed(2)} $targetCurrency',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Exchange Rate: 1 $baseCurrency = ${exchangeRate.toStringAsFixed(4)} $targetCurrency',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
