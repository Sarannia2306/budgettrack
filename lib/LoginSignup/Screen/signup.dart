import 'package:budgettrack/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../Services/authentication.dart';
import '../Widget/button.dart';
import '../Widget/snackbar.dart';
import '../Widget/text_field.dart';
import 'login.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
  }

  // Sign up user function
  void signupUser() async {
    setState(() {
      isLoading = true;
    });

    String res = await AuthMethod().signupUser(
        email: emailController.text,
        password: passwordController.text,
        name: nameController.text);

    if (res == "success") {
      // After successful signup, save user details to Realtime Database
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await _saveUserDetailsToRealtimeDatabase(user);
        print("User details saved to Realtime Database");
      } else {
        print("User is null, cannot save details");
      }

      setState(() {
        isLoading = false;
      });

      // Navigate to the HomeScreen after successful signup
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BottomNavScreen(),
        ),
      );
    } else {
      setState(() {
        isLoading = false;
      });

      // Show error message using Snackbar
      showSnackBar(context, res);
    }
  }

  // Function to save user details to Realtime Database
  Future<void> _saveUserDetailsToRealtimeDatabase(User user) async {
    try {
      // Get the reference for the user’s node in Realtime Database
      DatabaseReference usersRef = _database.ref('users/${user.uid}');

      // Save user details (name, email, uid) to Firebase Realtime Database
      await usersRef.set({
        'name': nameController.text,
        'email': emailController.text,
        'uid': user.uid,
      });

      // Optionally, update the user's display name in FirebaseAuth as well
      await user.updateDisplayName(nameController.text);
    } catch (e) {
      print("Error saving user details to Realtime Database: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SizedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: height / 2.8,
                child: Image.asset('assets/images/auth-sign.png'),
              ),

              // Name TextField
              TextFieldInput(
                icon: Icons.person,
                textEditingController: nameController,
                hintText: 'Enter your name',
                textInputType: TextInputType.text,
              ),
              SizedBox(height: 5),

              // Email TextField
              TextFieldInput(
                icon: Icons.email,
                textEditingController: emailController,
                hintText: 'Enter your email',
                textInputType: TextInputType.emailAddress,
              ),
              SizedBox(height: 5),

              // Password TextField
              TextFieldInput(
                icon: Icons.lock,
                textEditingController: passwordController,
                hintText: 'Enter your password',
                textInputType: TextInputType.text,
                isPass: true,
              ),
              SizedBox(height: 20),

              // Use MyButtons for the Sign Up button
              MyButtons(
                onTap: signupUser,
                text: "Sign Up",
              ),

              SizedBox(height: 30),

              // Already have an account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      " Login",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
