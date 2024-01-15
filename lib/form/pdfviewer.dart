import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PdfViewerPage extends StatefulWidget {
  final String fileUrl;
  final String formType;
  final String title;
  final String childrenId;

  PdfViewerPage(
      {required this.fileUrl,
      required this.formType,
      required this.title,
      required this.childrenId});

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late PDFDocument? document;
  bool isLoading = true;
  String permissionStatus = "";

  String? email;
  String? ic;

  @override
  void initState() {
    super.initState();
    loadPdf();
    // Initialize email and ic here
    email = FirebaseAuth.instance.currentUser?.email;
    ic = email?.substring(0, email?.indexOf("@"));
  }

  Future<void> loadPdf() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final CollectionReference formReference = firestore
          .collection('Forms')
          .doc(widget.title)
          .collection('PermissionStatus');

      DocumentSnapshot documentSnapshot =
          await formReference.doc(widget.childrenId).get();

      if (documentSnapshot.exists) {
        final data = documentSnapshot.data() as Map<String, dynamic>;
        final status = data['status'] as String;
        setState(() {
          permissionStatus = status;
        });
      }

      PDFDocument pdfDocument = await PDFDocument.fromURL(widget.fileUrl);
      setState(() {
        document = pdfDocument;
        isLoading = false;
      });
    } catch (error) {
      // Handle any potential errors when loading the PDF.
      print('Error loading PDF: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> createNewDoc() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      final CollectionReference formReference = firestore
          .collection('Forms')
          .doc(widget.title)
          .collection('PermissionStatus');

      DocumentReference documentReference =
          formReference.doc(widget.childrenId);

      Map<String, dynamic> documentData = {
        'status': permissionStatus,
      };

      await documentReference.update(
          documentData); // Use set instead of add to update the document

      Fluttertoast.showToast(
        msg: 'Permission Data saved successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      print('Document Successfully Updated');
    } catch (e) {
      print('Error updating document');
    }
  }

  // Function to show the bottom sheet with radio buttons.
  void _showPermissionBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Give Permission?'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio(
                        value: "Yes",
                        groupValue: permissionStatus,
                        onChanged: (value) {
                          setState(() {
                            permissionStatus = value as String;
                          });
                        },
                      ),
                      Text('Yes'),
                      Radio(
                        value: "No",
                        groupValue: permissionStatus,
                        onChanged: (value) {
                          setState(() {
                            permissionStatus = value as String;
                          });
                        },
                      ),
                      Text('No'),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Handle permissionStatus here
                      print('Permission Status: $permissionStatus');
                      createNewDoc(); // Call the function to create a new document
                      Navigator.of(context).pop();
                    },
                    child: Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.cyan, title: Text(widget.title)),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : (document != null
                ? PDFViewer(document: document!)
                : Text('Error loading PDF')),
      ),
      floatingActionButton: (widget.formType == "PermissionForm")
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    _showPermissionBottomSheet();
                  },
                  child: Icon(Icons.edit),
                ),
                SizedBox(width: 16),
                // Add some space between buttons
                // FloatingActionButton(
                //   onPressed: () {
                //     // Add the functionality for the second button
                //   },
                //   child: Icon(Icons.download), // Replace with the desired icon
                // ),
              ],
            )
          : SizedBox(width: 16), // Add some space between buttons

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
