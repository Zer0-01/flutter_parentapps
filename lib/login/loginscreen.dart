import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parentapps/login/signup_screen.dart';
import '../childrenscreen/childrenscreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _email = "", _password = "";
  final auth = FirebaseAuth.instance;
  String _errorMessage = "";

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Color(0xFFDFF4F3),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                "assets/Logo.png",
                width: 150,
                height: 150,
              ),
              const SizedBox(
                height: 30,
              ),
              Container(
                color: Color(0xFFDDE7F2),
                child: TextField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Nombor Telefon',
                    prefixIcon: Icon(Icons.person),
                    //errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _email = value.trim();
                      //_errorMessage = "";
                    });
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                color: Color(0xFFDDE7F2),
                child: TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _password = value.trim();
                      _errorMessage = "";
                    });
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF878ECD),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Log Masuk',
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () async {
                  try {
                    await auth.signInWithEmailAndPassword(
                        email: '$_email@smk.com', password: _password);

                    User? user = auth.currentUser;
                    if (user != null) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const ChildrenScreen(),
                        ),
                      );
                    }
                  } catch (e) {
                    setState(() {
                      _errorMessage = 'Invalid email or password';
                    });
                  }
                },
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      // TODO: Implement forgot password logic
                      print('Forgot Password');
                    },
                    child: Text(
                      'Lupa Password?',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      // TODO: Implement sign-up logic
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => SignupScreen(),
                      ));
                      print('Sign Up Here');
                    },
                    child: Text(
                      'Belum Mendaftar? Daftar Di Sini',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
