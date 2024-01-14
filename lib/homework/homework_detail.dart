import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:parentapps/homework/homework_file.dart';

// ignore: must_be_immutable
class homeworkDetails extends StatefulWidget {
  String? homeworkId;
  String? parentId;

  homeworkDetails({this.homeworkId, this.parentId});

  _homeworkDetailsState createState() => _homeworkDetailsState();
}

class _homeworkDetailsState extends State<homeworkDetails> {
  TextEditingController commentController = TextEditingController();

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
        String subject = data['subject'] as String;
        String? teacherId = data['teacherId'] as String?;
        String? title = data['title'] as String?;

        CollectionReference parentCollection =
            FirebaseFirestore.instance.collection('Parents');
        DocumentReference parentDoc = parentCollection.doc(widget.parentId);

        return StreamBuilder(
            stream: parentDoc.snapshots(),
            builder: (context, parentSnapshot) {
              if (parentSnapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator(); // or another loading indicator
              }

              if (parentSnapshot.hasError) {
                return Text('Error: ${parentSnapshot.error}');
              }

              if (!parentSnapshot.hasData || parentSnapshot.data == null) {
                return Text('No data available');
              }

              DocumentSnapshot parentDocSnapshot = parentSnapshot.data!;
              Map<String, dynamic> parentData =
                  parentDocSnapshot.data() as Map<String, dynamic>;
              String parentName = parentData['name'] as String;
              String parentId = parentDocSnapshot.id;

              return Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(
                  title: Text(homeworkId),
                  backgroundColor: Colors.cyan,
                ),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
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
                          'Due Date: ${dueDate != null ? DateFormat('yyyy-MM-dd').format(dueDate!.toDate()) : ''}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black,
                            ),
                            borderRadius: BorderRadius.circular(
                                10.0), // Adjust the value for the desired border radius
                          ),
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
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
                              Visibility(
                                visible: downloadURL != null,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                      builder: (context) => homeworkFile(
                                          homeworkId, title!, downloadURL!),
                                    ));
                                  },
                                  child: Text('View Attach File'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'Enter your comment',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        // Add a button to submit the comment
                        ElevatedButton(
                          onPressed: () {
                            String newComment = commentController.text.trim();
                            if (newComment.isNotEmpty) {
                              DateTime currentTime = DateTime.now();
                              // Save the new comment to the "Comment" subcollection
                              homeworkDoc.collection('Comment').add({
                                'userName': parentName,
                                'message': newComment,
                                'time': currentTime,
                              });

                              Fluttertoast.showToast(
                                msg: 'Comment Sent successfully',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.green,
                                textColor: Colors.white,
                              );

                              print(currentTime);

                              // Clear the input field after submitting the comment
                              commentController.clear();
                            }
                          },
                          child: Text('Send'),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: homeworkDoc
                              .collection('Comment')
                              .orderBy('time', descending: true)
                              .snapshots(),
                          builder: (context, commentSnapshot) {
                            if (commentSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }

                            if (commentSnapshot.hasError) {
                              return Text('Error: ${commentSnapshot.error}');
                            }

                            List<Widget> commentWidgets = [];
                            commentWidgets.add(
                              Text(
                                'Comments:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );

                            for (QueryDocumentSnapshot commentDoc
                                in commentSnapshot.data!.docs) {
                              Map<String, dynamic> commentData =
                                  commentDoc.data() as Map<String, dynamic>;
                              String userName =
                                  commentData['userName'] as String;
                              String message = commentData['message'] as String;
                              Timestamp? time =
                                  commentData['time'] as Timestamp?;

                              DateTime dateTime = time!.toDate();
                              String stringTime =
                                  "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}";

                              commentWidgets.add(
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(height: 10),
                                    Text(
                                      userName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      stringTime,
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    Text(message),
                                  ],
                                ),
                              );
                            }

                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(
                                    10.0), // Adjust the value for the desired border radius
                              ),
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: commentWidgets,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            });
      },
    );
  }
}
