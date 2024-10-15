import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:students_follow_app/pages/home/home.dart';
import 'package:students_follow_app/pages/home/informationForm.dart';
import 'package:students_follow_app/services/auth.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLogin = true;

  String? errorMessage;

  Future<void> registerUser() async {
    try {
      await Auth().registerUser(
          email: emailController.text, password: passwordController.text);
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const InformationForm()));
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<bool> checkIfUserExists(String uid) async {
    try {
      var collectionRef = FirebaseFirestore.instance.collection('users');
      var doc = await collectionRef.where('uid', isEqualTo: uid).get();
      return doc.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> signIn() async {
    try {
      await Auth().signIn(
          email: emailController.text, password: passwordController.text);

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        bool userExists = await checkIfUserExists(user.uid);

        if (userExists) {
          if (mounted) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const Home()));
          }
        } else {
          if (mounted) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const InformationForm()));
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> signOut() async {
    try {
      await Auth().signOut();
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.only(left: 30, right: 30, top: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 36),
            SvgPicture.asset("assets/icons/login.svg", height: 300),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SizedBox(
                width: double.infinity,
                child: TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: "your@email.adress",
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Icon(Icons.person),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  hintText: "**********",
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.lock),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
              ),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(errorMessage!,
                    style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (isLogin) {
                    signIn();
                  } else {
                    registerUser();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 226, 211, 245),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                child: isLogin
                    ? Text(
                        "Login".toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      )
                    : Text(
                        "Register".toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                setState(() {
                  isLogin = !isLogin;
                });
              },
              child: const Text("Henüz Hesabın Yok Mu ? Tıkla"),
            ),
          ],
        ),
      ),
    );
  }
}
