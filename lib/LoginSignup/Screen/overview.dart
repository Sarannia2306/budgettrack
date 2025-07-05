import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class OverviewScreen extends StatefulWidget {
  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  FirebaseAuth _auth = FirebaseAuth.instance;  // Instance initialization for FirebaseAuth
  FirebaseDatabase _database = FirebaseDatabase.instance;  // Instance initialization for FirebaseDatabase
  User? _user; // No need for late keyword

  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  List<double> incomeData = [0.0, 0.0, 0.0, 0.0]; // Default empty data for income
  List<double> expenseData = [0.0, 0.0, 0.0, 0.0]; // Default empty data for expenses

  bool _showIncome = true; // Flag to show income
  bool _showCompare = false; // Flag to show both income and expenses
  int _selectedIndex = 0;

  String _selectedMonth = 'Jun 2025'; // Default month
  List<String> _months = [
    'Jan 2025', 'Feb 2025', 'Mar 2025', 'Apr 2025', 'May 2025', 'Jun 2025',
    'Jul 2025', 'Aug 2025', 'Sep 2025', 'Oct 2025', 'Nov 2025', 'Dec 2025'
  ];

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;  // Fetch current user on initialization

    if (_user != null) {
      _loadUserData();
    }
  }

  void _loadUserData() async {
    DatabaseReference userRef = _database.ref('users/${_user?.uid}/transactions');

    // Fetch income data for all months
    DatabaseEvent incomeEvent = await userRef.child('income').once();
    if (incomeEvent.snapshot.exists) {
      final incomeDataFromDb = Map<String, dynamic>.from(incomeEvent.snapshot.value as Map);
      setState(() {
        _totalIncome = incomeDataFromDb.values.fold(0.0, (sum, item) => sum + (item['amount'] ?? 0.0));
        // Map the income data into a List<double> ensuring 12 months
        incomeData = List.generate(12, (index) {
          if (index < incomeDataFromDb.values.length) {
            return incomeDataFromDb.values.elementAt(index)['amount']?.toDouble() ?? 0.0;
          }
          return 0.0; // If no data for this month, set to 0
        });
      });
    } else {
      setState(() {
        _totalIncome = 0.0;
        incomeData = List.generate(12, (_) => 0.0);  // Ensure 12 months data
      });
    }

    // Fetch expense data for all months
    DatabaseEvent expenseEvent = await userRef.child('expenses').once();
    if (expenseEvent.snapshot.exists) {
      final expenseDataFromDb = Map<String, dynamic>.from(expenseEvent.snapshot.value as Map);
      setState(() {
        _totalExpenses = expenseDataFromDb.values.fold(0.0, (sum, item) => sum + (item['amount'] ?? 0.0));
        // Map the expense data into a List<double> ensuring 12 months
        expenseData = List.generate(12, (index) {
          if (index < expenseDataFromDb.values.length) {
            return expenseDataFromDb.values.elementAt(index)['amount']?.toDouble() ?? 0.0;
          }
          return 0.0; // If no data for this month, set to 0
        });
      });
    } else {
      setState(() {
        _totalExpenses = 0.0;
        expenseData = List.generate(12, (_) => 0.0);  // Ensure 12 months data
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Overview',
                style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income and Expenses Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCard('Total Income', _totalIncome, Colors.orange.shade700),
                _buildSummaryCard('Total Expenses', _totalExpenses, Colors.red.shade400),
              ],
            ),
            SizedBox(height: 30),
            // Month Dropdown next to the text
            Row(
              children: [
                Text(
                  'Statistics for ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Container(
                  width: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.shade300,
                        offset: Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: DropdownButton<String>(
                    value: _selectedMonth,
                    onChanged: (String? newMonth) {
                      setState(() {
                        _selectedMonth = newMonth!;
                      });
                    },
                    items: _months.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(value),
                        ),
                      );
                    }).toList(),
                    isExpanded: true,
                    underline: SizedBox(),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Chart Section
            SizedBox(height: 10),
            Expanded(child: _buildChart()),
            SizedBox(height: 20),
            // Income, Expense, and Compare Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton('Income', Colors.orange.shade300, _showIncome ? Colors.white : Colors.orange.shade900),
                _buildActionButton('Expenses', Colors.red.shade300, !_showIncome ? Colors.white : Colors.red.shade900),
                _buildActionButton('Compare', Colors.grey, _showCompare ? Colors.white : Colors.black87),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build summary card
  Widget _buildSummaryCard(String title, double value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: color)),
          SizedBox(height: 8),
          Text(
            'RM ${value.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // Helper function to build action buttons
  Widget _buildActionButton(String text, Color color, Color iconColor) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          if (text == 'Income') {
            _showIncome = true;
            _showCompare = false; // Disable compare when Income is clicked
          } else if (text == 'Expenses') {
            _showIncome = false;
            _showCompare = false; // Disable compare when Expenses is clicked
          } else {
            _showCompare = true; // Toggle compare
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(text, style: TextStyle(color: iconColor)),
    );
  }

  // Helper function to build the chart using fl_chart
  Widget _buildChart() {
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return Text('0');
                if (value == 1000) return Text('1k');
                if (value == 2000) return Text('2k');
                if (value == 3000) return Text('3k');
                if (value == 4000) return Text('4k');
                return Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return Text('Week 1');
                if (value == 1) return Text('Week 2');
                if (value == 2) return Text('Week 3');
                if (value == 3) return Text('Week 4');
                return Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            _showIncome || _showCompare
                ? BarChartRodData(toY: incomeData.isNotEmpty ? incomeData[0] : 0, color: Colors.orange, width: 20)
                : BarChartRodData(toY: 0, color: Colors.transparent, width: 20),
            !_showIncome || _showCompare
                ? BarChartRodData(toY: expenseData.isNotEmpty ? expenseData[0] : 0, color: Colors.red, width: 20)
                : BarChartRodData(toY: 0, color: Colors.transparent, width: 20),
          ]),
          BarChartGroupData(x: 1, barRods: [
            _showIncome || _showCompare
                ? BarChartRodData(toY: incomeData[1], color: Colors.orange, width: 20)
                : BarChartRodData(toY: 0, color: Colors.transparent, width: 20),
            !_showIncome || _showCompare
                ? BarChartRodData(toY: expenseData[1], color: Colors.red, width: 20)
                : BarChartRodData(toY: 0, color: Colors.transparent, width: 20),
          ]),
          BarChartGroupData(x: 2, barRods: [
            _showIncome || _showCompare
                ? BarChartRodData(toY: incomeData[2], color: Colors.orange, width: 20)
                : BarChartRodData(toY: 0, color: Colors.transparent, width: 20),
            !_showIncome || _showCompare
                ? BarChartRodData(toY: expenseData[2], color: Colors.red, width: 20)
                : BarChartRodData(toY: 0, color: Colors.transparent, width: 20),
          ]),
          BarChartGroupData(x: 3, barRods: [
            _showIncome || _showCompare
                ? BarChartRodData(toY: incomeData[3], color: Colors.orange, width: 20)
                : BarChartRodData(toY: 0, color: Colors.transparent, width: 20),
            !_showIncome || _showCompare
                ? BarChartRodData(toY: expenseData[3], color: Colors.red, width: 20)
                : BarChartRodData(toY: 0, color: Colors.transparent, width: 20),
          ]),
        ],
      ),
    );
  }
}
