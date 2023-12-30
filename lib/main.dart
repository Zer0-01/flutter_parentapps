import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  User? user = FirebaseAuth.instance.currentUser;
  runApp(MyApp(user));
}

class MyApp extends StatelessWidget {
  final User? user;

  const MyApp(this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    setupFirebaseMessaging();
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

Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Subscribe to the notification topic.
  messaging.subscribeToTopic('homeworkNotifications');

  // Handle background notifications.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle notifications when the app is in the foreground.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Handle the notification when the app is in the foreground.
  });

  // Handle notifications when the app is opened from a terminated state.
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // Handle the notification when the app is opened from a terminated state.
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle the background notification here.
}
