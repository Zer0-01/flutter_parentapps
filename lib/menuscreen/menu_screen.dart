import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parentapps/attendance/attendance_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parentapps/login/loginscreen.dart';
import '../form/fileselectionscreen.dart';
import 'package:badges/badges.dart' as badges;

import '../homework/homework_screen.dart';

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
  final String? childrenId;

  const MenuScreen(
      {super.key, required this.childrenName, required this.childrenId});

  @override
  Widget build(BuildContext context) {
    CollectionReference studentCollection =
        FirebaseFirestore.instance.collection("Students");
    Query children = studentCollection.where("name", isEqualTo: childrenName);

    CollectionReference attendanceCollection = FirebaseFirestore.instance
        .collection("Students")
        .doc(childrenId)
        .collection("Attendance");

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
        String parentId = data['parentId'] as String;
        String documentId = documentSnapshot.id;

        return StreamBuilder(
          stream:
              documentSnapshot.reference.collection("Attendance").snapshots(),
          builder: (context, attendanceSnapshot) {
            if (attendanceSnapshot.hasError) {
              return const Text("Something went wrong");
            }

            if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (!attendanceSnapshot.hasData ||
                attendanceSnapshot.data!.docs.isEmpty) {
              return const Text("No data available");
            }

            bool newAttendance = false;
            for (QueryDocumentSnapshot attendanceDocumentSnapshot
                in attendanceSnapshot.data!.docs) {
              Map<String, dynamic> attendanceData =
                  attendanceDocumentSnapshot.data() as Map<String, dynamic>;
              bool? isNewAttendance =
                  attendanceData['isNewAttendance'] as bool?;
              if (isNewAttendance != null && isNewAttendance) {
                newAttendance = true;
                break;
              }
            }

            CollectionReference homeworkCollection =
                FirebaseFirestore.instance.collection('Homework');
            Query homework =
                homeworkCollection.where('class', isEqualTo: childrenClass);

            return StreamBuilder(
                stream: homework.snapshots(),
                builder: (context, homeworkSnapshot) {
                  if (homeworkSnapshot.hasError) {
                    return const Text("Something went wrong");
                  }

                  if (homeworkSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (!homeworkSnapshot.hasData ||
                      homeworkSnapshot.data!.docs.isEmpty) {
                    return const Text("No data available");
                  }

                  bool newHomework = false;
                  for (QueryDocumentSnapshot homeworkDocumentSnapshot
                      in homeworkSnapshot.data!.docs) {
                    Map<String, dynamic> homeworkData =
                        homeworkDocumentSnapshot.data() as Map<String, dynamic>;
                    bool? isNewHomework =
                        homeworkData['isNewHomework'] as bool?;
                    if (isNewHomework != null && isNewHomework) {
                      newHomework = true;
                      break;
                    }
                  }

                  CollectionReference formCollection =
                      FirebaseFirestore.instance.collection('Forms');

                  return StreamBuilder(
                      stream: formCollection.snapshots(),
                      builder: (context, formSnapshot) {
                        if (formSnapshot.hasError) {
                          return const Text("Something went wrong");
                        }

                        if (formSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        if (!formSnapshot.hasData ||
                            formSnapshot.data!.docs.isEmpty) {
                          return const Text("No data available");
                        }

                        bool newForm = false;
                        for (QueryDocumentSnapshot formDocumentSnapshot
                            in formSnapshot.data!.docs) {
                          Map<String, dynamic> formData = formDocumentSnapshot
                              .data() as Map<String, dynamic>;
                          bool? isNewForm = formData['isNewForm'] as bool?;
                          if (isNewForm != null && isNewForm) {
                            newForm = true;
                            break;
                          }
                        }

                        return Scaffold(
                          appBar: AppBar(
                            backgroundColor: Theme.of(context).primaryColor,
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
                                        content: Text(
                                            'Are you sure you want to logout?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(false); // Cancel logout
                                            },
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(true); // Confirm logout
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
                                          builder: (context) =>
                                              const LoginScreen()),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: MainMenuCard(
                                      showBadge: newAttendance,
                                      colour: Colors.lightBlue.shade50,
                                      title: ('Attendance'),
                                      icons: Icons.fact_check,
                                      onpress: () {
                                        Navigator.of(context)
                                            .push(MaterialPageRoute(
                                          builder: (context) => GetAttendance(
                                              studentId: documentId,
                                              studentName: name),
                                        ));
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: MainMenuCard(
                                      showBadge: newHomework,
                                      colour: Colors.lightBlue.shade50,
                                      title: 'Homework',
                                      icons: Icons.assignment,
                                      onpress: () {
                                        Navigator.of(context)
                                            .push(MaterialPageRoute(
                                          builder: (context) => GetHomework(
                                              childrenClass, parentId),
                                        ));
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: MainMenuCard(
                                      showBadge: newForm,
                                      colour: Colors.lightBlue.shade50,
                                      title: 'Form',
                                      icons: Icons.insert_drive_file,
                                      onpress: () {
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    FileSelection(
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
                          bottomNavigationBar: BottomAppBar(
                            color: Colors.white,
                            // Set the background color of the bottom app bar
                            shape: CircularNotchedRectangle(),
                            // Notch in the bottom app bar for FAB
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.home),
                                  onPressed: () {
                                    // Handle Home button press
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.settings),
                                  onPressed: () {
                                    // Handle Settings button press
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                });
          },
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
  bool? showBadge;

  MainMenuCard(
      {super.key,
      required this.title,
      required this.icons,
      required this.onpress,
      required this.colour,
      this.showBadge});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colour,
      margin: const EdgeInsets.all(16),
      child: badges.Badge(
        position: badges.BadgePosition.topEnd(top: -5, end: -5),
        showBadge: showBadge != null && showBadge!,
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
                Icon(icons),
                // Icon on the left
                const SizedBox(width: 10),
                // Adding spacing between icon and text
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
      ),
    );
  }
}
