import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Register
  Future<void> registerUser(
      {required String email, required String password}) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
  }
  // Login

  Future<void> signIn({required String email, required String password}) async {
    await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<List<Map<String, dynamic>>?> fetchUserInfo() async {
    final String uid = Auth().currentUser!.uid;

    QuerySnapshot snapshot =
        await _firestore.collection('users').where('uid', isEqualTo: uid).get();

    if (snapshot.docs.isEmpty) {
      return [];
    } else {
      List<Map<String, dynamic>> userInfo = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return userInfo;
    }
  }

  Future<List<Map<String, dynamic>>?> fetchUserInfoByUid(String uid) async {

    QuerySnapshot snapshot =
        await _firestore.collection('users').where('uid', isEqualTo: uid).get();

    if (snapshot.docs.isEmpty) {
      return [];
    } else {
      List<Map<String, dynamic>> userInfo = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return userInfo;
    }
  }

}
