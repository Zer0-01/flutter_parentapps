import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  bool _isloading = false;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                "assets/logo2.png",
                width: 150,
                height: 150,
              ),
              const SizedBox(
                height: 30,
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(2, 5),
                  )
                ]),
                child: TextField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Phone Number',
                    prefixIcon: Icon(Icons.person),
                    border: InputBorder.none,
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
                decoration: BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(2, 5),
                  )
                ]),
                child: TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: InputBorder.none,
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
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isloading
                    ? CircularProgressIndicator()
                    : const Text(
                        'Login',
                        style: TextStyle(fontSize: 18),
                      ),
                onPressed: () async {
                  await signInWithEmailAndPassword();
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      navigateToSignUpScreen();
                    },
                    child: const Text(
                      'Not Registered Yet? Sign Up Here!!',
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

  // Function to handle sign in with email and password
  Future<void> signInWithEmailAndPassword() async {
    setState(() {
      _isloading = true;
    });

    try {
      await auth.signInWithEmailAndPassword(
          email: '$_email@smk.com', password: _password);

      User? user = auth.currentUser;

      if (user != null) {
        List<String> subscribedTopics = await saveFCMTokenToFirestore(_email);
        // Navigate to the ChildrenScreen
        navigateToChildrenScreen(subscribedTopics);
      }
    } catch (e) {
      // Handle authentication error and update error message
      setState(() {
        _errorMessage = 'Invalid email or password';
      });
    } finally {
      setState(() {
        _isloading = false;
      });
    }
  }

  Future<List<String>> saveFCMTokenToFirestore(String email) async {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

    // Get the FCM token
    String? fcmToken = await firebaseMessaging.getToken();

    // Save the FCM token to Firestore or wherever you want to store it
    // For example, you can use FirebaseFirestore
    if (fcmToken != null) {
      await FirebaseFirestore.instance
          .collection('Parents')
          .doc(email)
          .update({'fcmToken': fcmToken});

      CollectionReference parentCollection =
          FirebaseFirestore.instance.collection('Parents');
      DocumentReference parentDocument = parentCollection.doc(email);

      try {
        // Get the document snapshot
        DocumentSnapshot documentSnapshot = await parentDocument.get();

        // Check if the document exists
        if (documentSnapshot.exists) {
          // Access the data using the data() method
          Map<String, dynamic> data =
              documentSnapshot.data() as Map<String, dynamic>;

          String? childrenId = data['childrenId'];

          print('Children Id: $childrenId');

          CollectionReference studentsCollection =
              FirebaseFirestore.instance.collection('Students');
          DocumentReference studentDocument =
              studentsCollection.doc(childrenId);

          DocumentSnapshot studentSnapshot = await studentDocument.get();

          Map<String, dynamic> studentData =
              studentSnapshot.data() as Map<String, dynamic>;

          String classId = studentData['classID'];

          List<String> topicsToSubscribe = [];

          String topicAttendance = 'NotificationAttendance_$childrenId';
          String topicHomework =
              'NotificationHomework_${classId.replaceAll(' ', '_')}';

          String topicAnnouncementForm = 'NotificationAnnouncementForm';

          topicsToSubscribe.add(topicAttendance);
          topicsToSubscribe.add(topicHomework);
          topicsToSubscribe.add(topicAnnouncementForm);

          for (String topic in topicsToSubscribe) {
            await FirebaseMessaging.instance.subscribeToTopic(topic);
            print('Subscribe to topic: $topic');
          }

          // Return the list of topicsToSubscribe
          return topicsToSubscribe;
        } else {
          print('Document does not exist');
          // Return an empty list if the document doesn't exist
          return [];
        }
      } catch (e) {
        print('Error getting document: $e');
        // Return an empty list in case of an error
        return [];
      }
    }

    // Return an empty list if fcmToken is null
    return [];
  }

  // Function to navigate to the ChildrenScreen
  void navigateToChildrenScreen(List<String> subscribedTopics) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            ChildrenScreen(topicsToSubcribe: subscribedTopics),
      ),
    );
  }

  // Function to navigate to the Sign Up screen
  void navigateToSignUpScreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SignupScreen(),
    ));
  }
}
