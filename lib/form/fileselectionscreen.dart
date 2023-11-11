import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'pdfviewer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FileSelection extends StatefulWidget {
  final String collectionName; // The name of the Firestore collection
  final String childrenName;
  final String childrenId;

  FileSelection({required this.collectionName, required this.childrenName, required this.childrenId});

  @override
  _FileSelectionState createState() => _FileSelectionState();
}

class _FileSelectionState extends State<FileSelection> {
  List<DocumentSnapshot> permissions = [];
  List<DocumentSnapshot> announcements = [];

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
                  .contains(widget.childrenName))
          .toList();
      announcements = querySnapshot.docs
          .where((doc) => doc.data()['formType'] == 'Announcement')
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
              Tab(text: 'Permission'),
              Tab(text: 'Announcement'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FileList(files: permissions, childrenId: widget.childrenId),
            FileList(files: announcements, childrenId: widget.childrenId,),
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

        return Card(
          elevation: 2,
          margin: EdgeInsets.all(8),
          child: ListTile(
            title: Text(document['title']),
            // Replace 'fileName' with your Firestore field name

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PdfViewerPage(fileUrl: fileUrl, formType: formType, title: title, childrenId: childrenId ,),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
