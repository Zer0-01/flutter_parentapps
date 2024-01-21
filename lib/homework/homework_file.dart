import 'package:flutter/material.dart';

class homeworkFile extends StatefulWidget {
  String homeworkId;
  String title;
  String downloadURL;

  homeworkFile(this.homeworkId, this.title, this.downloadURL);

  _homeworkFileState createState() => _homeworkFileState();
}

class _homeworkFileState extends State<homeworkFile> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadFileFromFirebase();
  }

  Future<void> loadFileFromFirebase() async {
    try {



      setState(() {
      });
    } catch (error) {
      print("Error loading PDF: $error");
      setState(() {
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

  }
}
