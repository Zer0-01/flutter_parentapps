// Import necessary Dart and Flutter packages
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  // Declare initial variables
  late String initialKenyataan = '';

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
                              "Hadir",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Tidak Hadir",
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

                Timestamp date = data['date'] as Timestamp;
                bool status = data['status'] as bool;
                String time = data['time'] as String;

                // Check if 'kenyataan' field exists in the document
                bool kenyataanFieldExist = data.containsKey('kenyataan');

                // If 'kenyataan' field exists, get its value; otherwise, assign an empty string
                String kenyataan =
                    kenyataanFieldExist ? data['kenyataan'] as String : '';

                // Check if 'fileName' field exists in the document
                bool fileNameFieldExist = data.containsKey('fileName');

                // If 'fileName' field exists, get its value; otherwise, assign an empty string
                String fileName =
                    fileNameFieldExist ? data['fileName'] as String : '';

                DateTime toDate = date.toDate();
                String formattedDate = DateFormat('dd MMM y').format(toDate);

                String attendanceDocId = document.id;

                return ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text("$formattedDate ($time)"),
                      ),
                      Expanded(
                        child: status
                            ? const Align(
                                alignment: Alignment.center,
                                child: Icon(Icons.radio_button_on),
                              )
                            : const Icon(Icons.radio_button_off),
                      ),
                      Expanded(
                        child: !status
                            ? const Align(
                                alignment: Alignment.center,
                                child: Icon(Icons.radio_button_on),
                              )
                            : const Icon(Icons.radio_button_off),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _showConfirmationDialog(context, attendanceDocId);
                          },
                          child: (kenyataan.isEmpty && fileName.isEmpty)
                              ? const Icon(Icons.add)
                              : const Icon((Icons.create_rounded)),
                        ),
                      ),
                    ],
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
  Future<void> _showConfirmationDialog(
      BuildContext context, String attendanceDocId) async {
    // Initialize variables
    String kenyataan = "";
    String? filePath;
    String studentId = widget.studentId;
    String studentName = widget.studentName;
    String documentId = attendanceDocId;
    String? fileName;

    // Retrieve document snapshot from Firestore
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
        await FirebaseFirestore.instance
            .collection('Students')
            .doc(studentId)
            .collection('Attendance')
            .doc(attendanceDocId)
            .get();

    // Check if the 'kenyataan' field exists
    bool kenyataanFieldExists =
        documentSnapshot.data()?.containsKey('kenyataan') ?? false;

    // If 'kenyataan' field exists, get its value
    if (kenyataanFieldExists) {
      kenyataan = documentSnapshot['kenyataan'] as String;
    }

    // Check if the 'fileName' field exists
    bool fileNameFieldExists =
        documentSnapshot.data()?.containsKey('fileName') ?? false;

    // If 'fileName' field exists, get its value
    if (fileNameFieldExists) {
      fileName = documentSnapshot['fileName'] as String;
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
                    Text('Date: $documentId'),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Kenyataan',
                      ),
                      controller: TextEditingController(text: kenyataan),
                      onChanged: (value) {
                        kenyataan = value;
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
                              filePath = result.files.first.path!;
                              fileName = filePath!.split('/').last;
                              setState(() {});
                            }
                          },
                          child: const Text('Pick PDF'),
                        ),
                        const SizedBox(width: 10),
                        Text(filePath != null || fileName != null
                            ? fileName! // Displaying only the file name
                            : 'No file selected'),
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
                        await uploadFileToFirebaseStorage(filePath);

                    // Save 'kenyataan' and file reference to Firestore
                    storeDataInFirebase(
                        kenyataan, uploadedFileURL, fileName, documentId);

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

  // Store updated data in Firestore
  Future<void> storeDataInFirebase(String kenyataan, String? fileURL,
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
