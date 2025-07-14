import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budgettrack/LoginSignup/Widget/snackbar.dart';

TextEditingController emailController = TextEditingController();
final FirebaseAuth auth = FirebaseAuth.instance;

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  @override
  void initState() {
    super.initState();

    // Show the dialog as soon as the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showForgotPasswordDialog(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Return a transparent Scaffold so nothing visible shows up
    return const Scaffold(
      backgroundColor: Colors.transparent,
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(),
                    const Text(
                      "Forgot Your Password",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(this.context).pop(); // Close screen
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Enter your email",
                    hintText: "eg abc@gmail.com",
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () async {
                    if (emailController.text.isEmpty) {
                      showSnackBar(context, "Please enter your email.");
                      return;
                    }

                    try {
                      await auth.sendPasswordResetEmail(
                          email: emailController.text);
                      showSnackBar(context,
                          "Reset password link sent. Please check your email.");
                    } on FirebaseAuthException catch (e) {
                      showSnackBar(context, e.message ?? "Error occurred.");
                    }

                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(this.context).pop(); // Close screen
                    emailController.clear();
                  },
                  child: const Text(
                    "Send",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
