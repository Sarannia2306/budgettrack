import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthMethod {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // SignUp User
  Future<String> signupUser({
    required String email,
    required String password,
    required String name,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
        // Register user in Firebase Authentication
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Save user details to Realtime Database
        await _saveUserDetailsToRealtimeDatabase(cred.user!, name, email);

        res = "success";  // Return success if everything goes smoothly
      } else {
        res = "Please fill all the fields";  // If any field is empty
      }
    } on FirebaseAuthException catch (err) {
      res = err.message ?? "An unknown error occurred";  // Handle FirebaseAuthException
    } catch (err) {
      res = err.toString();  // Handle general errors
    }
    return res;
  }

  // Save user details to Realtime Database
  Future<void> _saveUserDetailsToRealtimeDatabase(User user, String name, String email) async {
    try {
      // Get reference to the user node in Realtime Database
      DatabaseReference usersRef = _database.ref('users/${user.uid}');

      // Save user details (name, email, uid) to Firebase Realtime Database
      await usersRef.set({
        'name': name,
        'email': email,
        'uid': user.uid,
      });

      // Optionally, update the user's display name in FirebaseAuth as well
      await user.updateDisplayName(name);
    } catch (e) {
      print("Error saving user details to Realtime Database: $e");
    }
  }

  // LogIn User
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        // Logging in user with email and password
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        res = "success";  // Successful login
      } else {
        res = "Please fill all the fields";  // If fields are empty
      }
    } on FirebaseAuthException catch (err) {
      res = err.message ?? "An unknown error occurred";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // SignOut User
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
