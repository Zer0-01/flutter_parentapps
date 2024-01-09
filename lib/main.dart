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
    String? phoneNumber = user!.email;
    // Split the email address using '@' as a delimiter
    List<String>? parts = phoneNumber?.split('@');

    // Use the first part as the phone number
    String? parentId = parts?[0];
    print('Phone Number: $phoneNumber');
    print('Parent Id: $parentId');

    await saveFCMTokenToFirestore(parentId!);
  }

  runApp(MyApp(user));
}

Future<void> saveFCMTokenToFirestore(String email) async {
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

        String topic = 'NotificationAttendance_$childrenId';

        await FirebaseMessaging.instance.subscribeToTopic(topic);
        print('Subscribed to topic: $topic');
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Error getting document: $e');
    }
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
