import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class homeworkDetails extends StatefulWidget {
  String? homeworkId;

  homeworkDetails({this.homeworkId});

  _homeworkDetailsState createState() => _homeworkDetailsState();
}

class _homeworkDetailsState extends State<homeworkDetails> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    CollectionReference homeworkCollection =
        FirebaseFirestore.instance.collection('Homework');
    DocumentReference homeworkDoc = homeworkCollection.doc(widget.homeworkId);

    return StreamBuilder<DocumentSnapshot>(
      stream: homeworkDoc.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // or another loading indicator
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Text('No data available');
        }

        DocumentSnapshot homeworkSnapshot = snapshot.data!;
        Map<String, dynamic> data =
            homeworkSnapshot.data() as Map<String, dynamic>;
        String homeworkId = homeworkSnapshot.id;
        String? className = data['class'] as String?;
        String? description = data['description'] as String?;
        String? downloadURL = data['downloadURL'] as String?;
        Timestamp? dueDate = data['dueDate'] as Timestamp?;
        String? subject = data['subject'] as String?;
        String? teacherId = data['teacherId'] as String?;
        String? title = data['title'] as String?;

        print(homeworkId);

        // Now you can use data and homeworkId as needed

        return Scaffold(
          appBar: AppBar(
            title: Text(homeworkId),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? '',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Class: ${className ?? ''}',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  'Subject: ${subject ?? ''}',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  'Due Date: ${dueDate?.toDate() ?? ''}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description ?? 'No description available.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                // Add more widgets as needed for other details
              ],
            ),
          ),
        );
      },
    );
  }
}
