import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parentapps/attendance/attendancescreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parentapps/login/loginscreen.dart';
import '../form/fileselectionscreen.dart';

import '../homework/homeworkscreen.dart';

// Function to extract the name before "BIN" or "BINTI"
String extractName(String fullName) {
  final match = RegExp(r'(.+)\s+(?:BIN|BINTI)').firstMatch(fullName);
  if (match != null) {
    return match.group(1)!;
  }
  return fullName; // Return the full name if "BIN" or "BINTI" is not found
}

class MenuScreen extends StatelessWidget {
  final String childrenName;

  const MenuScreen({super.key, required this.childrenName});

  @override
  Widget build(BuildContext context) {
    CollectionReference studentCollection =
        FirebaseFirestore.instance.collection("Students");

    Query children = studentCollection.where("name", isEqualTo: childrenName);

    return StreamBuilder<QuerySnapshot>(
      stream: children.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Something went wrong");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No data available");
        }
        QueryDocumentSnapshot documentSnapshot = snapshot.data!.docs[0];
        Map<String, dynamic> data =
            snapshot.data?.docs[0].data() as Map<String, dynamic>;
        String name = data['name'] as String;
        String childrenClass = data['classID'] as String;
        String documentId = documentSnapshot.id;

        return Scaffold(
          appBar: AppBar(
            title: Text(extractName(name)),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  // Show a confirmation dialog
                  bool confirmLogout = await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Confirm Logout'),
                        content: Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false); // Cancel logout
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true); // Confirm logout
                            },
                            child: Text('Logout'),
                          ),
                        ],
                      );
                    },
                  );

                  // If user confirms logout, sign out
                  if (confirmLogout == true) {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) =>
                          false, // Clear all previous routes
                    );
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: MainMenuCard(
                      colour: Colors.lightBlue.shade50,
                      title: ('Attendance'),
                      icons: Icons.fact_check,
                      onpress: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => GetAttendance(
                              studentId: documentId, studentName: name),
                        ));
                      },
                    ),
                  ),
                  Expanded(
                    child: MainMenuCard(
                      colour: Colors.lightBlue.shade50,
                      title: 'Homework',
                      icons: Icons.assignment,
                      onpress: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => GetHomework(childrenClass),
                        ));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                      child: MainMenuCard(
                    colour: Colors.lightBlue.shade50,
                    title: 'Grade',
                    icons: Icons.auto_graph,
                    onpress: () {},
                  )),
                  Expanded(
                    child: MainMenuCard(
                      colour: Colors.lightBlue.shade50,
                      title: 'Form',
                      icons: Icons.insert_drive_file,
                      onpress: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => FileSelection(
                                  collectionName: "Forms",
                                  childrenName: name,
                                  childrenId: documentId,
                                )));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class MainMenuCard extends StatelessWidget {
  final String title;
  final IconData icons;
  final Function() onpress;
  final Color colour;

  const MainMenuCard(
      {super.key,
      required this.title,
      required this.icons,
      required this.onpress,
      required this.colour});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colour,
      margin: const EdgeInsets.all(16),
      child: TextButton(
        onPressed: onpress,
        style: TextButton.styleFrom(
          foregroundColor: Colors.black,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            // Change to Row
            children: [
              Icon(icons), // Icon on the left
              const SizedBox(width: 10), // Adding spacing between icon and text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // Align text to the left
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  // Adding spacing between title and description
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
