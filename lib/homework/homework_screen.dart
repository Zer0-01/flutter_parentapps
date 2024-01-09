import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homework_detail.dart';

class GetHomework extends StatefulWidget {
  String className;
  String parentId;

  GetHomework(this.className, this.parentId, {super.key});

  @override
  _GetHomeworkState createState() => _GetHomeworkState();
}

class _GetHomeworkState extends State<GetHomework> {
  @override
  void initState() {
    super.initState();
    updateIsNewHomeworkField();
  }

  Future<void> updateIsNewHomeworkField() async {
    print(widget.className);
    // Get a reference to the documents in the 'Homework' collection
    QuerySnapshot homeworkDocs = await FirebaseFirestore.instance
        .collection('Homework')
        .where('class', isEqualTo: widget.className)
        .get();

    // Update each document's hasNewAttendance field to false
    for (QueryDocumentSnapshot doc in homeworkDocs.docs) {
      try {
        await doc.reference.update({
          'isNewHomework': false,
        });
      } catch (error) {
        print('Error updating hasNewHomework field: $error');
        // Handle the error as needed
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    CollectionReference homeworkCollection =
        FirebaseFirestore.instance.collection('Homework');

    Query homework =
        homeworkCollection.where('class', isEqualTo: widget.className);

    return StreamBuilder<QuerySnapshot>(
      stream: homework.orderBy('dueDate', descending: true).snapshots(),
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
          appBar: AppBar(
            title: const Text('HOMEWORK'),
          ),
          body: ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              String homeworkId = snapshot.data!.docs[index].id;
              String? className = data['class'] as String?;
              String? description = data['description'] as String?;
              String? downloadURL = data['downloadURL'] as String?;
              Timestamp? dueDate = data['dueDate'] as Timestamp?;
              String? subject = data['subject'] as String?;
              String? teacherId = data['teacherId'] as String?;
              String? title = data['title'] as String?;

              DateTime currentDate = DateTime.now();
              int daysRemaining;
              DateTime due = dueDate!.toDate();
              Color colourStatus;

              if (due.isBefore(currentDate)) {
                daysRemaining = 0;
                colourStatus = Colors.grey;
              } else {
                final difference = due.difference(currentDate).inDays;
                daysRemaining = difference;

                if (difference <= 3) {
                  colourStatus = Colors.red.shade100;
                } else if (difference <= 5) {
                  colourStatus = Colors.yellow.shade100;
                } else {
                  colourStatus = Colors.white;
                }
              }

              return ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => homeworkDetails(
                                homeworkId: homeworkId,
                                parentId: widget.parentId,
                              )));
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(16),
                      backgroundColor: colourStatus,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              Icons.category,
                              // Replace with an appropriate icon
                              color: Colors.black, // Set icon color to black
                            ),
                            Text(
                              "$daysRemaining days left",
                              style: TextStyle(
                                color: Colors.black,
                                // Set text color to black
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          subject!,
                          style: TextStyle(
                            color: Colors.black, // Set text color to black
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          title!,
                          style: TextStyle(
                            color: Colors.black, // Set text color to black
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          description!,
                          style: TextStyle(
                            color: Colors.black, // Set text color to black
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ));
            },
          ),
        );
      },
    );
  }

//method to get 2 stream at the same time
// @override
// Widget build(BuildContext context) {
//   // TODO: implement build
//   CollectionReference homeworkCollection = FirebaseFirestore.instance
//       .collection('HomeworkTest1')
//       .doc(className)
//       .collection('21-8-23');
//
//   CollectionReference studentCollection = FirebaseFirestore.instance
//     .collection('ParentsTest1');
//
//   Stream<List<QuerySnapshot>> a = StreamZip([homeworkCollection.snapshots(), studentCollection.snapshots()]);
//
//
//   return StreamBuilder<List<QuerySnapshot>>(
//     stream: StreamZip([homeworkCollection.snapshots(), studentCollection.snapshots()]),//homeworkCollection.snapshots(),
//     builder: (context, snapshot) {
//       if (snapshot.hasError) {
//         return Text("Something went wrong");
//       }
//
//       if (snapshot.connectionState == ConnectionState.waiting) {
//         return CircularProgressIndicator();
//       }
//
//       if (!snapshot.hasData || snapshot.data!.elementAt(0).docs.isEmpty || snapshot.data!.elementAt(1).docs.isEmpty) {
//         return Text("No data available: d0=${snapshot.data!.elementAt(0).docs.isEmpty}, d1=${snapshot.data!.elementAt(1).docs.isEmpty}");
//       }
//
//       Map<String, dynamic> homeworkData = snapshot.data!.elementAt(0).docs[0].data() as Map<String, dynamic>;
//       Map<String, dynamic> parent = snapshot.data!.elementAt(1).docs[0].data() as Map<String, dynamic>;
//
//       return Scaffold(
//         appBar: AppBar(
//           title: Text("Attendance"),
//         ),
//         body: Column(children: [
//           Text("Homework 0: subject=${homeworkData['subject']}"),
//           Text("Description 0: description=${parent['description']}")
//         ]),
//       );
//     },
//   );
// }
}
