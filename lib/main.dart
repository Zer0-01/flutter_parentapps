import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:parentapps/childrenscreen/childrenscreen.dart';
import 'package:parentapps/login/loginscreen.dart';
import 'FCM_service.dart';
import 'firebase_options.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FlutterDownloader.initialize(
    debug: true,
    ignoreSsl: true,
  );

  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    String? userPhoneNumber = user.email.toString();

    List<String>? parts = userPhoneNumber.split('@');
    String? phoneNumber = parts[0];

    await saveFCMTokenToFirestore(phoneNumber);
    // Navigate to the ChildrenScreen
  }

  // Initialize Firebase Cloud Messaging
  await FCMService().initFCM();

  runApp(MyApp(user));
}

Future<void> saveFCMTokenToFirestore(String email) async {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

// Get the FCM token
  String? fcmToken = await _firebaseMessaging.getToken();

  print("moshi: $fcmToken");

// Save the FCM token to Firestore or wherever you want to store it
// For example, you can use FirebaseFirestore
  if (fcmToken != null) {
    await FirebaseFirestore.instance
        .collection('Parents')
        .doc(email)
        .update({'fcmToken': fcmToken});
  }
}

class MyApp extends StatelessWidget {
  final User? user;

  const MyApp(this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parent Application',
      theme: ThemeData(
        primaryColor: Colors.cyan,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: user != null ? const ChildrenScreen() : const LoginScreen(),
    );
  }
}
