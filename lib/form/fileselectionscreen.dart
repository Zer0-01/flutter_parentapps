import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pdfviewer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FileSelection extends StatefulWidget {
  final String collectionName; // The name of the Firestore collection
  final String childrenName;
  final String childrenId;

  FileSelection(
      {required this.collectionName,
      required this.childrenName,
      required this.childrenId});

  @override
  _FileSelectionState createState() => _FileSelectionState();
}

class _FileSelectionState extends State<FileSelection> {
  List<DocumentSnapshot> permissions = [];
  List<DocumentSnapshot> announcements = [];
  String selectedCategory = '';

  @override
  void initState() {
    super.initState();
    listFiles();
    updateIsNewForm();
  }

  Future<void> updateIsNewForm() async {
    // Reference to the 'forms' collection
    CollectionReference formsCollection =
        FirebaseFirestore.instance.collection('Forms');

    // Get all documents in the 'forms' collection
    QuerySnapshot formsDocs = await formsCollection.get();

    // Update the isNewForm field to true for each document
    for (QueryDocumentSnapshot doc in formsDocs.docs) {
      try {
        await doc.reference.update({
          'isNewForm': false,
        });
      } catch (error) {
        print('Error updating isNewForm field: $error');
        // Handle the error as needed
      }
    }
  }

  Future<void> listFiles() async {
    final collection =
        FirebaseFirestore.instance.collection(widget.collectionName);
    final querySnapshot =
        await collection.orderBy('uploadedDate', descending: true).get();

    setState(() {
      permissions = querySnapshot.docs
          .where((doc) =>
              doc.data()['formType'] == 'PermissionForm' &&
              (doc.data()['selectedStudents'] as List)
                  .contains(widget.childrenName) &&
              (selectedCategory.isEmpty ||
                  (doc.data()['categories'] as String) == selectedCategory))
          .toList();
      announcements = querySnapshot.docs
          .where((doc) =>
              doc.data()['formType'] == 'Announcement' &&
              (selectedCategory.isEmpty ||
                  (doc.data()['categories'] as String) == selectedCategory))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.cyan,
          title: Text('FORMS'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Permission'),
              Tab(text: 'Announcement'),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Dropdown for category selection
              Row(
                children: [
                  Text('Filter:'),
                  SizedBox(
                    width: 14,
                  ),
                  DropdownButton<String>(
                    value: selectedCategory,
                    hint: Text('Filter by Category'),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCategory = newValue!;
                        listFiles();
                      });
                    },
                    items: <String>['', 'Kokurikulum', 'Kurikulum', 'HEM']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    FileList(files: permissions, childrenId: widget.childrenId),
                    FileList(
                      files: announcements,
                      childrenId: widget.childrenId,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FileList extends StatelessWidget {
  final List<DocumentSnapshot> files;
  final String childrenId;

  FileList({required this.files, required this.childrenId});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        DocumentSnapshot document = files[index];
        final fileUrl = document[
            'fileURL']; // Replace 'downloadUrl' with your Firestore field name

        final formType = document['formType'];

        final title = document['title'];

        final category = document['categories'];
        final Timestamp uploadedDate = document['uploadedDate'];

        final DateTime dateTime = uploadedDate.toDate();

// Format the DateTime to a String
        final String formattedDate = DateFormat('dd MMM yyyy').format(dateTime);

        final String formId = document.id;

        return Card(
          elevation: 2,
          margin: EdgeInsets.all(8),
          child: ListTile(
            title: Text(document['title']),
            // Replace 'fileName' with your Firestore field name
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formattedDate),
                Text(category),
              ],
            ),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfViewerPage(
                    fileUrl: fileUrl,
                    formType: formType,
                    title: title,
                    childrenId: childrenId,
                    formId: formId,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
