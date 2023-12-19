import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';

class homeworkFile extends StatefulWidget {
  String homeworkId;
  String title;
  String downloadURL;

  homeworkFile(this.homeworkId, this.title, this.downloadURL);

  _homeworkFileState createState() => _homeworkFileState();
}

class _homeworkFileState extends State<homeworkFile> {
  bool _isLoading = true;
  PDFDocument? _pdfDocument;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadFileFromFirebase();
  }

  Future<void> loadFileFromFirebase() async {
    try {
      CollectionReference homeworkCollection =
          FirebaseFirestore.instance.collection("homework");
      DocumentReference homeworkDoc = homeworkCollection.doc(widget.homeworkId);

      DocumentSnapshot homeworkSnapshot = await homeworkDoc.get();

      Map<String, dynamic> data =
          homeworkSnapshot.data() as Map<String, dynamic>;

      PDFDocument pdfDocument = await PDFDocument.fromURL(widget.downloadURL);
      setState(() {
        _pdfDocument = pdfDocument;
        _isLoading = false;
      });
    } catch (error) {
      print("Error loading PDF: $error");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Image.network(widget.downloadURL),
    );

    throw UnimplementedError();
  }
}
