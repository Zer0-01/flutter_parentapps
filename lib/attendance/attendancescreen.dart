import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class GetAttendance extends StatelessWidget {
  final String studentId;
  final String studentName;

  const GetAttendance({super.key, required this.studentId, required this.studentName});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    CollectionReference attendanceCollection = FirebaseFirestore.instance
        .collection('Students')
        .doc(studentId)
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

                Map<String, dynamic> data = snapshot.data!.docs[index - 1]
                    .data() as Map<String, dynamic>;
                Timestamp date = data['date'] as Timestamp;
                bool status = data['status'] as bool;
                String time = data['time'] as String;

                DateTime toDate = date.toDate();
                String formattedDate = DateFormat('dd MMM y').format(toDate);

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
                            _showConfirmationDialog(context);
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

  Future<void> _showConfirmationDialog(BuildContext context) async {
    String kenyataan;

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
                SizedBox(height: 10,),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Kenyataan',
                  ),
                  onChanged: (value) {
                    kenyataan = value;
                  },
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                // Perform the action here
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
}
