// Import necessary Dart and Flutter packages
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
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
                            "Tarikh",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Kehadiran",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Catatan",
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
                String? fileName = data['fileName'] as String?;
                String? fileURL = data['fileURL'] as String?;
                bool? hasNewAttendance = data['hasNewAttendance'] as bool?;
                String? statement = data['statement'] as String?;
                bool? status = data['status'] as bool?;
                String? time = data['time'] as String?;

                String attendanceDocId = document.id;

                DateTime? toDate = date?.toDate();
                String formattedDate = DateFormat('dd MMM y').format(toDate!);

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
                          child: Text("$formattedDate ($time)"),
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

  Future<void> _showConfirmationDialog(
      BuildContext context, String attendanceDocId) async {
    String studentId = widget.studentId;
    String studentName = widget.studentName;

    CollectionReference attendanceCollection = FirebaseFirestore.instance
        .collection('Students')
        .doc(studentId)
        .collection('Attendance');
    DocumentReference attendanceDoc = attendanceCollection.doc(attendanceDocId);

    DocumentSnapshot attendanceSnapshot = await attendanceDoc.get();

    Map<String, dynamic> data =
        attendanceSnapshot.data() as Map<String, dynamic>;

    Timestamp? date = data['date'] as Timestamp?;
    String? fileName = data['fileName'] as String?;
    String? fileURL = data['fileURL'] as String?;
    bool? hasNewAttendance = data['hasNewAttendance'] as bool?;
    String? statement = data['statement'] as String?;
    bool? status = data['status'] as bool?;
    String? time = data['time'] as String?;

    DateTime? toDate = date?.toDate();
    String formattedDate = DateFormat('dd MMM y').format(toDate!);

    if (fileName == null) {
      fileName = "Tiada Fail";
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Catatan'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text("Tarikh: $formattedDate"),
                    Text("Nama: $studentName"),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Kenyataan',
                      ),
                      controller: TextEditingController(text: statement),
                      onChanged: (value) {
                        statement = value;
                      },
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'],
                        );
                        if (result != null) {
                          fileURL = result.files.first.path!;
                          fileName = fileURL!.split('/').last;
                          setState(
                              () {}); // Trigger a rebuild with updated state
                        }
                      },
                      child: const Text("Pilih fail"),
                    ),
                    Text(fileName!), // Display the updated fileName
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Hantar'),
                  onPressed: () async {
                    // Upload file to Firebase Storage
                    String? uploadedFileURL =
                        await uploadFileToFirebaseStorage(fileURL);

                    // Save 'kenyataan' and file reference to Firestore
                    storeDataInFirebase(
                        statement!, uploadedFileURL, fileName, attendanceDocId);

                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show confirmation dialog for updating attendance details
  Future<void> _showConfirmationDialog2(
      BuildContext context, String attendanceDocId) async {
    // Initialize variables

    String studentId = widget.studentId;
    String studentName = widget.studentName;
    String documentId = attendanceDocId;

    // Retrieve document snapshot from Firestore
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
        await FirebaseFirestore.instance
            .collection('Students')
            .doc(studentId)
            .collection('Attendance')
            .doc(attendanceDocId)
            .get();

    // Check if the 'kenyataan' field exists
    // bool kenyataanFieldExists =
    //     documentSnapshot.data()?.containsKey('kenyataan') ?? false;
    //
    // // If 'kenyataan' field exists, get its value
    // if (kenyataanFieldExists) {
    //   kenyataan = documentSnapshot['kenyataan'] as String;
    // }

    // Check if the 'fileName' field exists
    // bool fileNameFieldExists =
    //     documentSnapshot.data()?.containsKey('fileName') ?? false;
    //
    // // If 'fileName' field exists, get its value
    // if (fileNameFieldExists) {
    //   fileName = documentSnapshot['fileName'] as String;
    // }

    Timestamp? date = documentSnapshot['date'] as Timestamp?;
    String? fileName = documentSnapshot['fileName'] as String?;
    String? fileURL = documentSnapshot['fileURL'] as String?;
    bool? hasNewAttendance = documentSnapshot['hasNewAttendance'] as bool?;
    String? statement = documentSnapshot['statement'] as String?;
    bool? status = documentSnapshot['status'] as bool?;
    String? time = documentSnapshot['time'] as String?;

    DateTime? toDate = date?.toDate();
    String formattedDate = DateFormat('dd MMM y').format(toDate!);

    if (fileName == null) {
      fileName = "Tiada fail";
    }

    // Show the confirmation dialog
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Catatan'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('ID Pelajar: $studentId'),
                    Text('Nama: $studentName'),
                    Text('Tarikh: $formattedDate'),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Kenyataan',
                      ),
                      controller: TextEditingController(text: statement),
                      onChanged: (value) {
                        statement = value;
                      },
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            // Pick a PDF file using file picker
                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                            );

                            // If a file is picked, update file path and name
                            if (result != null) {
                              fileURL = result.files.first.path!;
                              fileName = fileURL!.split('/').last;
                              setState(() {});
                            }
                          },
                          child: const Text('Pick PDF'),
                        ),
                        const SizedBox(width: 10),
                        Text(fileName!),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Yes'),
                  onPressed: () async {
                    // Upload file to Firebase Storage
                    String? uploadedFileURL =
                        await uploadFileToFirebaseStorage(fileURL);

                    // Save 'kenyataan' and file reference to Firestore
                    storeDataInFirebase(
                        statement!, uploadedFileURL, fileName, documentId);

                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

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
