// Import necessary Dart and Flutter packages
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'attendance_statement.dart';

// Define a Flutter StatefulWidget for getting attendance
class GetAttendance extends StatefulWidget {
  final String studentId;
  final String studentName;

  // Constructor for GetAttendance widget
  const GetAttendance({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  _GetAttendanceState createState() => _GetAttendanceState();
}

// Define the state for GetAttendance widget
class _GetAttendanceState extends State<GetAttendance> {
  DateTime? selectedMonth;

  @override
  void initState() {
    super.initState();
    updateIsNewAttendance();
  }

  Future<void> updateIsNewAttendance() async {
    CollectionReference attendanceCollection = FirebaseFirestore.instance
        .collection('Students')
        .doc(widget.studentId)
        .collection('Attendance');

    QuerySnapshot attendanceDocs = await attendanceCollection.get();

    for (QueryDocumentSnapshot doc in attendanceDocs.docs) {
      try {
        await doc.reference.update({
          'isNewAttendance': false,
        });
      } catch (error) {
        print('Error updating isNewAttendance field: $error');
        // Handle the error as needed
      }
    }
  }

  void navigateToNextPage(BuildContext context, Widget nextPage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => nextPage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Create a reference to the attendance collection in Firestore
    CollectionReference attendanceCollection = FirebaseFirestore.instance
        .collection('Students')
        .doc(widget.studentId)
        .collection('Attendance');

    // Build a stream builder to handle real-time data changes
    return StreamBuilder<QuerySnapshot>(
      stream:
          attendanceCollection.orderBy('date', descending: true).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        // Handle errors
        if (snapshot.hasError) {
          return const Text("Something went wrong");
        }

        // Show a loading indicator while waiting for data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        // If there is no data, display a message
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No data available");
        }

        // Build the attendance list UI
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.cyan,
            title: const Text("ATTENDANCE"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(10.0),
            child: ListView.builder(
              itemCount: snapshot.data!.docs.length + 1,
              itemBuilder: (context, index) {
                // Display header row
                if (index == 0) {
                  return ListTile(
                    tileColor: Colors.teal.shade100,
                    title: const Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Date",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Status",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Remark",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Display attendance data
                QueryDocumentSnapshot<Object?> document =
                    snapshot.data!.docs[index - 1];

                // Explicitly cast the 'Object' type to 'Map<String, dynamic>'
                Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;

                Timestamp? date = data['date'] as Timestamp?;
                bool? status = data['status'] as bool?;
                String? time = data['time'] as String?;

                String attendanceDocId = document.id;

                DateTime? toDate = date?.toDate();
                String formattedDate = DateFormat('dd MMM y').format(toDate!);

                String? formattedTime;

                if (time != null) {
                  try {
                    // Parse the raw time string
                    DateTime parsedTime = DateFormat.Hms().parse(time);

                    // Format the time in "hh:mm am/pm" format
                    formattedTime = DateFormat('hh:mm a').format(parsedTime);
                  } catch (e) {
                    print('Error parsing or formatting time: $e');
                    formattedTime = null;
                  }
                }

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey), // Set border color
                    borderRadius: BorderRadius.all(
                        Radius.circular(8.0)), // Set border radius
                  ),
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text("$formattedDate ($formattedTime)"),
                        ),
                        Expanded(
                          child: Container(
                            child: Text(''),
                            decoration: BoxDecoration(
                              color: status! ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              //_showConfirmationDialog(context, attendanceDocId);
                              navigateToNextPage(
                                  context,
                                  AttendanceStatement(
                                    studentId: widget.studentId,
                                    attendanceId: attendanceDocId,
                                  ));
                            },
                            child: Icon(Icons.create_rounded),
                            // child: (statement != null)
                            //     ? const Icon(Icons.create_rounded)
                            //     : const Icon((Icons.add)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }


  // Show confirmation dialog for updating attendance details

  // Upload a file to Firebase Storage
  Future<String?> uploadFileToFirebaseStorage(String? filePath) async {
    if (filePath != null) {
      FirebaseStorage storage = FirebaseStorage.instance;
      String fileName = filePath.split('/').last;
      Reference storageReference = storage.ref().child('attendance/$fileName');

      File file = File(filePath);
      await storageReference.putFile(file);

      // Get the download URL of the uploaded file
      String downloadURL = await storageReference.getDownloadURL();
      return downloadURL;
    }
    return null;
  }

  Future<void> storeDataInFirebase(String statement, String? fileURL,
      String? fileName, String attendanceDocId) async {
    CollectionReference attendanceCollection = FirebaseFirestore.instance
        .collection('Students')
        .doc(widget.studentId)
        .collection('Attendance');

    DocumentReference attendanceDoc = attendanceCollection.doc(attendanceDocId);

    await attendanceDoc.update(
        {'statement': statement, 'fileURL': fileURL, 'fileName': fileName});
  }

  // Store updated data in Firestore
  Future<void> storeDataInFirebase2(String kenyataan, String? fileURL,
      String? fileName, String attendanceDocId) async {
    CollectionReference attendanceCollection = FirebaseFirestore.instance
        .collection('Students')
        .doc(widget.studentId)
        .collection('Attendance');

    // Assuming you have a specific document ID or a way to identify the document
    // If not, you might need to modify this logic accordingly
    DocumentReference docRef = attendanceCollection.doc(attendanceDocId);

    // Get the current document data
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
        await docRef.get() as DocumentSnapshot<Map<String, dynamic>>;

    // Check if the 'kenyataan' field exists
    bool kenyataanFieldExists =
        documentSnapshot.data()?.containsKey('kenyataan') ?? false;

    // Check if the 'fileURL' field exists
    bool fileURLFieldExists =
        documentSnapshot.data()?.containsKey('fileURL') ?? false;

    // Check if the 'fileName' field exists
    bool fileNameFieldExist =
        documentSnapshot.data()?.containsKey('fileName') ?? false;

    // Define the data to update in Firestore
    Map<String, dynamic> dataToUpdate = {
      'kenyataan': kenyataan,
    };

    // If fileURL is available, add it to the data
    if (fileURL != null) {
      // If 'fileURL' field exists, update its value
      if (fileURLFieldExists) {
        dataToUpdate['fileURL'] = fileURL;
      } else {
        // 'fileURL' field doesn't exist, create it
        dataToUpdate['fileURL'] = fileURL;
      }
    }

    // If fileName is available, add it to the data
    if (fileName != null) {
      if (fileNameFieldExist) {
        dataToUpdate['fileName'] = fileName;
      } else {
        dataToUpdate['fileName'] = fileName;
      }
    }

    // If 'kenyataan' field exists, update its value
    if (kenyataanFieldExists) {
      await docRef.update(dataToUpdate);
    } else {
      // 'kenyataan' field doesn't exist, create it
      await docRef.set(
          dataToUpdate,
          SetOptions(
              merge:
                  true)); // Use merge option to add 'kenyataan' without deleting existing fields
    }
  }
}
