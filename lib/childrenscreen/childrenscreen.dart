import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:parentapps/menuscreen/menu_screen.dart';

class ChildrenScreen extends StatelessWidget {
  final List<String> topicsToSubcribe;


  const ChildrenScreen({required this.topicsToSubcribe, super.key});



  @override
  Widget build(BuildContext context) {

    print('Subsribed topic: $topicsToSubcribe');
    // TODO: implement build
    String? email = FirebaseAuth.instance.currentUser?.email;
    String? ic = email?.substring(0, email.indexOf("@"));

    CollectionReference studentCollection =
        FirebaseFirestore.instance.collection("Students");

    Query children = studentCollection.where("parentId", isEqualTo: ic);

    return StreamBuilder(
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

        return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Choose your children:',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: List<Widget>.generate(
                      snapshot.data?.docs.length ?? 0,
                      (index) {
                        Map<String, dynamic> data = snapshot.data?.docs[index]
                            .data() as Map<String, dynamic>;

                        String childrenName = data['name'] as String;
                        String? childrenId = snapshot.data?.docs[index].id;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => MenuScreen(
                                    childrenName: childrenName,
                                    childrenId: childrenId,
                                    subscribedTopics: topicsToSubcribe),
                              ));
                              // Handle button press for the specific child
                              // For example, navigate to a new screen or perform an action
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("$childrenName ($childrenId)"),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ));
      },
    );
  }
}
