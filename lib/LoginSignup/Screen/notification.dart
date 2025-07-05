import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:budgettrack/LoginSignup/Widget/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late FirebaseDatabase _database;
  late FirebaseAuth _auth;
  late User? _user;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _database = FirebaseDatabase.instance;
    _user = _auth.currentUser;

    if (_user != null) {
      _loadNotifications();
    }
  }

  // Load notifications from Firebase
  void _loadNotifications() async {
    DatabaseReference userRef = _database.ref('users/${_user?.uid}/notifications');
    DatabaseEvent event = await userRef.once();

    if (event.snapshot.exists) {
      final Map<dynamic, dynamic> notificationsData = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      List<NotificationModel> notifications = [];
      notificationsData.forEach((key, value) {
        notifications.add(NotificationModel.fromMap(Map<String, dynamic>.from(value)));
      });

      setState(() {
        _notifications = notifications;
      });
    }
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
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center the title
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Notifications',
                    style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          leading: IconButton( // Custom back arrow
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: _notifications.isEmpty
          ? Center(child: Text('No notifications available.'))
          : ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: EdgeInsets.all(16.0),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _notifications[index].message,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _notifications[index].type == 'goal'
                          ? Colors.blue
                          : _notifications[index].type == 'income'
                          ? Colors.green.shade400
                          : Colors.red.shade400,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Date: ${_notifications[index].date}',
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
