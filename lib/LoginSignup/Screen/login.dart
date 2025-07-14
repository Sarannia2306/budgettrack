import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:budgettrack/main.dart';
import 'package:budgettrack/LoginSignup/Screen/signup.dart';
import 'package:budgettrack/LoginSignup/Widget/snackbar.dart';
import 'package:budgettrack/LoginSignup/Widget/button.dart';
import 'package:budgettrack/PasswordForgot/forgot_password.dart';
import 'package:budgettrack/LoginSignup/Services/authentication.dart';
import 'package:budgettrack/LoginWithGoogle/google_auth.dart';
import '../Widget/text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  // Email and password auth part
  void loginUser() async {
    setState(() {
      isLoading = true;
    });

    String res = await AuthMethod().loginUser(
      email: emailController.text,
      password: passwordController.text,
    );

    if (res == "success") {
      setState(() {
        isLoading = false;
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BottomNavScreen(),
        ),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, res);
    }
  }

  // Google Sign-In
  void loginWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseServices().signInWithGoogle();

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Realtime Database reference
        DatabaseReference userRef = FirebaseDatabase.instance.ref("users/${user.uid}");

        final snapshot = await userRef.get();

        // If user doesn't exist, create new user profile in Realtime Database
        if (!snapshot.exists) {
          await userRef.set({
            'uid': user.uid,
            'name': user.displayName,
            'email': user.email,
          });
        }

        setState(() {
          isLoading = false;
        });

        // Navigate to the HomeScreen after successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomNavScreen()),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, 'Google sign-in failed: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: height / 2.7,
                child: Image.asset('assets/images/auth.png'),
              ),
              TextFieldInput(
                textEditingController: emailController,
                hintText: 'Enter your email',
                icon: Icons.email,
                textInputType: TextInputType.emailAddress,
              ),
              SizedBox(height: 3),

              TextFieldInput(
                textEditingController: passwordController,
                hintText: 'Enter your password',
                icon: Icons.lock,
                textInputType: TextInputType.text,
                isPass: true,
              ),
              SizedBox(height: 0),

              // Navigate to Forgot Password Screen
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ForgotPassword(),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),

              MyButtons(
                onTap: loginUser,
                text: "Log In",
              ),
              SizedBox(height: 0),

              // Divider
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: Colors.black26)),
                  const Text("  or  "),
                  Expanded(child: Container(height: 1, color: Colors.black26)),
                ],
              ),

              // Google Sign-In Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                  onPressed: loginWithGoogle,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Image.network(
                          "https://ouch-cdn2.icons8.com/VGHyfDgzIiyEwg3RIll1nYupfj653vnEPRLr0AeoJ8g/rs:fit:456:456/czM6Ly9pY29uczgu/b3VjaC1wcm9kLmFz/c2V0cy9wbmcvODg2/LzRjNzU2YThjLTQx/MjgtNGZlZS04MDNl/LTAwMTM0YzEwOTMy/Ny5wbmc.png",
                          height: 35,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Continue with Google",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                      )
                    ],
                  ),
                ),
              ),

              // Don't have an account? Go to the signup screen
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
