import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> registerUser(
      {required String email, required String password}) async {
    UserCredential userCredential =
        await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await userCredential.user?.sendEmailVerification();

    await signOut();
  }

  Future<void> signIn({required String email, required String password}) async {
    UserCredential userCredential =
        await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user?.emailVerified == false) {
      await _firebaseAuth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Lütfen giriş yapmadan önce e-posta adresinizi doğrulayın.',
      );
    }
  }

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

  Future<List<Map<String, dynamic>>?> fetchUserInfoByUid(String? uid) async {
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

  Future<List<dynamic>> fetchFollowersByUid(String? uid) async {
    QuerySnapshot snapshot = await _firestore
        .collection('followers')
        .where('userId', isEqualTo: uid)
        .get();

    if (snapshot.docs.isEmpty) {
      return [];
    } else {
      List<Map<String, dynamic>> userFollowers = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return userFollowers;
    }
  }
}
