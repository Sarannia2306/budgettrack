import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AddExpenseScreen extends StatefulWidget {
  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  DateTime selectedDate = DateTime.now();
  TextEditingController titleController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  List<String> categories = ['Groceries', 'Bills', 'Entertainment'];
  String selectedCategory = '';
  TextEditingController newCategoryController = TextEditingController();

  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseDatabase _database = FirebaseDatabase.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;  // Ensure the user is set on screen load
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
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Add Expense',
                style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Picker
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: _selectDate,
                ),
                Text(
                  "${selectedDate.toLocal()}".split(' ')[0],
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Expense Title
            _buildTextField(titleController, 'Expense Title'),
            SizedBox(height: 20),

            // Amount
            _buildTextField(amountController, 'Amount', prefix: '\RM'),
            SizedBox(height: 20),

            // Category Selection
            Text("Category", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                for (var category in categories)
                  _buildCategoryButton(category),
                // "+" button to add a new category
                IconButton(
                  icon: Icon(Icons.add, color: Colors.purple.shade200),
                  onPressed: _showCategoryDialog,
                ),
              ],
            ),
            SizedBox(height: 20),

            // Add Expense Button
            _buildAddButton('Add Expense'),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    ) ?? selectedDate;

    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
  }

  Widget _buildTextField(TextEditingController controller, String label, {String prefix = ''}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildCategoryButton(String category) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedCategory = category;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedCategory == category
            ? Colors.red.shade600
            : Colors.red.shade600,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        category,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Category'),
          content: TextField(
            controller: newCategoryController,
            decoration: InputDecoration(
              labelText: 'Category Name',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (newCategoryController.text.isNotEmpty) {
                  setState(() {
                    categories.add(newCategoryController.text);
                    newCategoryController.clear();
                  });
                }
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddButton(String buttonText) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveExpenseToFirebase,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          buttonText,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _saveExpenseToFirebase() async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    if (titleController.text.isNotEmpty && amountController.text.isNotEmpty && selectedCategory.isNotEmpty) {
      final String title = titleController.text;
      final double amount = double.parse(amountController.text);
      final String category = selectedCategory;
      final String time = selectedDate.toLocal().toString().split(' ')[0]; // Date as string

      // Reference to the user's transactions/expenses in Firebase
      DatabaseReference userRef = _database.ref('users/${_user?.uid}/transactions/expenses');

      // Create new expense data
      final newExpense = {
        'title': title,
        'amount': amount,
        'category': category,
        'time': time,
      };

      try {
        // Push new expense data to Firebase
        await userRef.push().set(newExpense);

        // Add notification
        _addNotification("Successfully added expense of RM $amount for $title on $time", 'expense');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense added successfully!')),
        );

        // Clear input fields
        titleController.clear();
        amountController.clear();
        setState(() {
          selectedCategory = ''; // Reset selected category
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding expense: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields.')),
      );
    }
  }

  // Add notification method
  void _addNotification(String message, String type) {
    if (_user == null) return;

    final notification = {
      'message': message,
      'date': DateTime.now().toString(),
      'type': type,
    };

    // Save to Firebase
    DatabaseReference userRef = _database.ref('users/${_user?.uid}/notifications');
    userRef.push().set(notification);
  }
}
