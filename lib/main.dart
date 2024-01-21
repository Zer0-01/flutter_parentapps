import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:parentapps/childrenscreen/childrenscreen.dart';
import 'package:parentapps/login/loginscreen.dart';
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

  List<String> subscribedTopics = [];

  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    String? phoneNumber = user!.email;
    // Split the email address using '@' as a delimiter
    List<String>? parts = phoneNumber?.split('@');

    // Use the first part as the phone number
    String? parentId = parts?[0];
    print('Phone Number: $phoneNumber');
    print('Parent Id: $parentId');

    subscribedTopics = await saveFCMTokenToFirestore(parentId!);
  }

  runApp(MyApp(user, subscribedTopics));
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
        DocumentReference studentDocument = studentsCollection.doc(childrenId);

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

class MyApp extends StatelessWidget {
  final User? user;
  final List<String> subscribedTopics;

  const MyApp(this.user, this.subscribedTopics, {super.key});

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
      home: user != null
          ? ChildrenScreen(
              topicsToSubcribe: subscribedTopics,
            )
          : const LoginScreen(),
    );
  }
}
