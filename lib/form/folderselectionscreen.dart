// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'fileselectionscreen.dart';
//
// class FolderSelection extends StatefulWidget {
//   _FolderSelectionState createState() => _FolderSelectionState();
// }
//
// class _FolderSelectionState extends State<FolderSelection> {
//   final storage = FirebaseStorage.instance;
//   List<Reference> folders = [];
//
//   void initState() {
//     super.initState();
//     listFolders();
//   }
//
//   Future<void> listFolders() async {
//     ListResult result = await FirebaseStorage.instance.ref().listAll();
//     setState(() {
//       folders = result.prefixes;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Forms'),
//       ),
//       body: ListView.builder(
//         itemCount: folders.length,
//         itemBuilder: (context, index) {
//           Reference folder = folders[index];
//           return Card(
//             elevation: 2, // Add some elevation for a card effect
//             margin: EdgeInsets.all(8), // Add margin for spacing
//             child: ListTile(
//               title: Text(folder.name),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => FileSelection(collectionName: "Forms"),
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
