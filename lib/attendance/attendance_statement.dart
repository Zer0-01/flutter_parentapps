import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AttendanceStatement extends StatefulWidget {
  String? studentId;
  String? attendanceId;

  AttendanceStatement({Key? key, this.studentId, this.attendanceId})
      : super(key: key);

  @override
  _AttendanceStatementState createState() => _AttendanceStatementState(
      studentId: studentId, attendanceId: attendanceId);
}

class _AttendanceStatementState extends State<AttendanceStatement> {
  String? studentId;
  String? attendanceId;

  _AttendanceStatementState({this.studentId, this.attendanceId});

  TextEditingController statementController = TextEditingController();
  String? selectedFileName;
  FilePickerResult? result;

  // Function to handle file picking
  Future<void> pickFile() async {
    result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        selectedFileName = result!.files.single.name;
      });
    }
  }

  // Function to upload the selected file to Firebase Storage
  Future<String?> uploadFile(File file) async {
    try {
      // Replace 'your_storage_path' with the desired path in Firebase Storage
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('your_storage_path/$selectedFileName');

      UploadTask uploadTask = storageRef.putFile(file);

      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

      String downloadURL = await taskSnapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (error) {
      print('Error uploading file: $error');
      return null;
    }
  }

  void saveData() async {
    String statement = statementController.text;

    // Check if the statement is not empty
    if (statement.isNotEmpty) {
      // Replace 'your_collection' with the name of your Firestore collection
      CollectionReference attendanceCollection = FirebaseFirestore.instance
          .collection('Students')
          .doc(studentId)
          .collection('Attendance');
      // Replace 'your_document_id' with the document ID where you want to store the statement
      DocumentReference attendanceDoc = attendanceCollection.doc(attendanceId);

      try {
        // Upload the file if selectedFileName is not null
        if (selectedFileName != null) {
          File file = File(result!.files.single.path!);
          String? fileURL = await uploadFile(file);

          // Update the document with the new file URL
          await attendanceDoc.update({
            'statement': statement,
            'fileName': selectedFileName,
            'fileURL': fileURL,
          });
        } else {
          // Update the document without the file URL
          await attendanceDoc.update({'statement': statement});
        }

        Fluttertoast.showToast(
          msg: 'Data saved successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        print('Data saved successfully.');
      } catch (error) {
        print('Error saving data: $error');
        // Handle the error as needed
      }
    } else {
      Fluttertoast.showToast(
        msg: 'Statement is empty. Please enter a statement.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      // Handle case where the statement is empty
      print('Statement is empty. Please enter a statement.');
    }
  }

  @override
  Widget build(BuildContext context) {
    CollectionReference attendanceCollection = FirebaseFirestore.instance
        .collection('Students')
        .doc(studentId)
        .collection('Attendance');

    DocumentReference attendanceDoc = attendanceCollection.doc(attendanceId);

    return StreamBuilder(
      stream: attendanceDoc.snapshots(),
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

        DocumentSnapshot attendanceSnapshot = snapshot.data!;
        Map<String, dynamic> attendanceData =
            attendanceSnapshot.data() as Map<String, dynamic>;
        Timestamp? timestampDate = attendanceData['date'] ?? 'N/A';
        String? date = timestampDate != null
            ? DateFormat('dd MMM y').format(timestampDate.toDate())
            : 'N/A/';
        String? fileName = attendanceData['fileName'] ?? 'N/A';
        String? fileURL = attendanceData['fileURl'] ?? 'N/A';
        String? statement = attendanceData['statement'] ?? 'N/A';
        String? time = attendanceData['time'] ?? 'N/A';
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
        bool? status = attendanceData['status'];

        statementController = TextEditingController(text: statement);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.cyan,
            title: Text('Attendance Details'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text('Date'),
                    subtitle: Text(date),
                  ),
                  ListTile(
                    title: Text('Time'),
                    subtitle: Text(formattedTime!),
                  ),
                  ListTile(
                    title: Text('Status'),
                    subtitle: Text(status != null
                        ? (status ? 'Present' : 'Absent')
                        : 'N/A'),
                  ),
                  ListTile(
                    title: Text('Statement'),
                    subtitle: TextField(
                      controller: statementController,
                      decoration: InputDecoration(
                        hintText: 'Enter statement',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text('Supporting Document'),
                    subtitle: Text(selectedFileName ?? fileName!),
                  ),
                  ElevatedButton(
                    onPressed: pickFile,
                    child: Text('Pick Document (Only .pdf format)'),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ElevatedButton(
                      onPressed: saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.green, // Set the background color to green
                      ),
                      child: Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    throw UnimplementedError();
  }
}
