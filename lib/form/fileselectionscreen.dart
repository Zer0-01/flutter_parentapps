import 'package:flutter/material.dart';
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
  }

  Future<void> listFiles() async {
    final collection =
        FirebaseFirestore.instance.collection(widget.collectionName);
    final querySnapshot = await collection.get();

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
          title: Text(widget.collectionName),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Kebenaran'),
              Tab(text: 'Pengumuman'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Dropdown for category selection
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

        return Card(
          elevation: 2,
          margin: EdgeInsets.all(8),
          child: ListTile(
            title: Text(document['title']),
            // Replace 'fileName' with your Firestore field name
            subtitle: Text(category),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfViewerPage(
                    fileUrl: fileUrl,
                    formType: formType,
                    title: title,
                    childrenId: childrenId,
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
