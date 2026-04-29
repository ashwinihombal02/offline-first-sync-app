import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> upsertNote(Map<String, dynamic> data) async {
    await firestore
        .collection('notes')
        .doc(data['id'])
        .set(data);
  }

  Future<void> deleteNote(String id) async {
    await firestore
        .collection('notes')
        .doc(id)
        .delete();
  }
}