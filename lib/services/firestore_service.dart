import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  FirebaseFirestore get db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get users =>
      db.collection('users');
  CollectionReference<Map<String, dynamic>> get tracks =>
      db.collection('tracks');
  CollectionReference<Map<String, dynamic>> get videos =>
      db.collection('videos');
  CollectionReference<Map<String, dynamic>> get playlists =>
      db.collection('playlists');

  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      users.doc(uid);

  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream(String uid) =>
      userDoc(uid).snapshots();

  Future<void> ensureUserDocument({
    required String uid,
    required String email,
    required String name,
    String? avatar,
  }) async {
    final ref = userDoc(uid);
    final snap = await ref.get();
    if (snap.exists) {
      // Keep profile fields fresh without overwriting counters.
      await ref.set(
        <String, dynamic>{
          'email': email,
          'name': name,
          'avatar': avatar,
        },
        SetOptions(merge: true),
      );
      return;
    }

    await ref.set(<String, dynamic>{
      'email': email,
      'name': name,
      'avatar': avatar,
      'followers': 0,
      'following': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

