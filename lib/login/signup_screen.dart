import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<SignupScreen> {
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    CollectionReference parentCollection =
        FirebaseFirestore.instance.collection('Parents');

    return StreamBuilder(
      stream: parentCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Something went wrong");
        }

        // Show a loading indicator while waiting for data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        // If there is no data, display a message
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No data available");
        }

        List<String> documentIds =
            snapshot.data!.docs.map((doc) => doc.id).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text('Sign Up'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _onSignUpButtonPressed(documentIds);
                  },
                  child: Text('Sign Up'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSignUpButtonPressed(List<String> documentIds) async {
    String enteredPhoneNumber = phoneNumberController.text;
    bool phoneNumberExists = documentIds.contains(enteredPhoneNumber);

    if (phoneNumberExists) {
      // Phone number exists, proceed with creating user

      // Create user in Firebase Authentication
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: '$enteredPhoneNumber@smk.com',
          password: passwordController.text,
        );

        // TODO: Add additional logic if user creation is successful

        print('User created successfully');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Berjaya Mendaftar'),
            content: Text("Pendaftaran anda berjaya"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Text("Back to loginscreen"),
              )
            ],
          ),
        );
      } catch (error) {
        // Handle any errors during user creation
        print('Error creating user: $error');
      }
    } else {
      // Phone number doesn't exist, show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Your number is not in the school database.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
