import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class GetAttendance extends StatefulWidget {
  final String studentId;
  final String studentName;

  const GetAttendance(
      {super.key, required this.studentId, required this.studentName});

  @override
  _GetAttendanceState createState() => _GetAttendanceState();
}

class _GetAttendanceState extends State<GetAttendance> {
  late String initialKenyataan = '';

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    CollectionReference attendanceCollection = FirebaseFirestore.instance
        .collection('Students')
        .doc(widget.studentId)
        .collection('Attendance');

    return StreamBuilder<QuerySnapshot>(
      stream:
          attendanceCollection.orderBy('date', descending: true).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
            title: const Text("ATTENDANCE"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(10.0),
            child: ListView.builder(
              itemCount: snapshot.data!.docs.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    tileColor: Colors.teal.shade100,
                    title: const Row(
                      children: [
                        Expanded(
                            child: Text(
                                style: TextStyle(fontWeight: FontWeight.bold),
                                "Tarikh")),
                        Expanded(
                            child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    "Hadir"))),
                        Expanded(
                            child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    "Tidak Hadir"))),
                        Expanded(
                            child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    "Catatan"))),
                      ],
                    ),
                  );
                }

                QueryDocumentSnapshot<Object?> document =
                    snapshot.data!.docs[index - 1];
                Timestamp date = document['date'] as Timestamp;
                bool status = document['status'] as bool;
                String time = document['time'] as String;

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
                        child: GestureDetector(
                          onTap: () {
                            _showConfirmationDialog(context, attendanceDocId);
                          },
                          child: Icon(Icons.create_rounded),
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

  Future<void> _showConfirmationDialog(
      BuildContext context, String attendanceDocId) async {
    String kenyataan = "";
    String? filePath;
    String studentId = widget.studentId;
    String studentName = widget.studentName;
    String documentId = attendanceDocId;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Catatan'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('ID Pelajar: $studentId'),
                Text('Nama: $studentName'),
                Text('Date: $documentId'),
                SizedBox(
                  height: 10,
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Kenyataan',
                  ),
                  onChanged: (value) {
                    kenyataan = value;
                  },
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'],
                        );

                        if (result != null) {
                          filePath = result.files.first.path!;
                          setState(() {});
                        }
                      },
                      child: Text('Pick PDF'),
                    ),
                    SizedBox(width: 10),
                    Text(filePath ?? 'No file selected'),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                storeKenyataanInFirebase(kenyataan, documentId);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> storeKenyataanInFirebase(
      String kenyataan, String attendanceDocId) async {
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

    if (kenyataanFieldExists) {
      // 'kenyataan' field exists, update its value
      await docRef.update({
        'kenyataan': kenyataan,
      });
    } else {
      // 'kenyataan' field doesn't exist, create it
      await docRef.set(
          {
            'kenyataan': kenyataan,
            // You can add other fields as needed
          },
          SetOptions(
              merge:
                  true)); // Use merge option to add 'kenyataan' without deleting existing fields
    }
  }
}

// Function to store kenyataan value in Firebase
