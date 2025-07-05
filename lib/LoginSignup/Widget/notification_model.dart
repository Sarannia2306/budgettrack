class NotificationModel {
  final String message;
  final String date;
  final String type; // Type can be "income", "expense", or "goal"

  NotificationModel({
    required this.message,
    required this.date,
    required this.type,
  });

  // Convert notification data to a Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'date': date,
      'type': type,
    };
  }

  // Convert Map back to a NotificationModel instance
  static NotificationModel fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      message: map['message'],
      date: map['date'],
      type: map['type'],
    );
  }
}
