import 'package:Tudora/pages/auth/register.dart';
import 'package:Tudora/pages/home/informationForm.dart';
import 'package:Tudora/pages/home/menu-home.dart';
import 'package:Tudora/services/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? errorMessage;

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
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const MenuHome()));
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
      String? errorText;
      print("e.code ${e.code}");
      switch (e.code) {
        case 'invalid-email':
          errorText = "Geçersiz e-posta adresi girdiniz.";
          break;
        case 'user-disabled':
          errorText = "Kullanıcı devre dışı bırakıldı.";
          break;
        case 'user-not-found':
          errorText = "Girilen bilgiler hatalı. Lütfen tekrar deneyin.";
          break;
        case 'invalid-credential':
          errorText = "Girilen bilgiler hatalı. Lütfen tekrar deneyin.";
          break;
        case 'wrong-password':
          errorText = "Girilen bilgiler hatalı. Lütfen tekrar deneyin.";
          break;
        case 'email-already-in-use':
          errorText = "Bu e-posta adresi zaten kullanılıyor.";
          break;
        case 'operation-not-allowed':
          errorText = "Bu işlem izin verilmedi.";
          break;
        default:
          errorText = "Bir hata oluştu. Lütfen tekrar deneyin.";
      }

      setState(() {
        errorMessage = errorText;
      });
    }
  }

  Future<void> resetPassword() async {
    String email = emailController.text;
    if (email.isEmpty) {
      setState(() {
        errorMessage = "Lütfen e-posta adresinizi girin.";
      });
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Şifre sıfırlama e-postası gönderildi!")),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    double height = MediaQuery.sizeOf(context).height;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Padding(
        padding: EdgeInsets.only(
            left: width / 13.7, right: width / 13.7, top: height / 17.8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: height / 74.17),
              Text(
                "Tekrar Hoşgeldin 🤗",
                style: TextStyle(
                    fontSize: height / 31,
                    fontFamily: "Poppins-Bold",
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: height / 24.73),
              SvgPicture.asset("assets/icons/login.svg", height: height / 3),
              SizedBox(height: height / 30),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                    vertical: height / 74.16, horizontal: width / 34.25),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(25.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: emailController,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(right: width / 34.25),
                          child: const Icon(Icons.email),
                        ),
                        hintText: "email",
                        hintStyle: TextStyle(
                            color: emailController.text.isEmpty
                                ? const Color.fromARGB(220, 168, 163, 161)
                                : const Color(0xFF282625)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: height / 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(25.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(right: 12.0),
                          child: Icon(Icons.lock),
                        ),
                        hintText: "*********",
                        hintStyle: TextStyle(
                            color: emailController.text.isEmpty
                                ? const Color.fromARGB(220, 168, 163, 161)
                                : const Color(0xFF282625)),
                      ),
                    ),
                  ],
                ),
              ),
              if (errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(top: height / 81.1),
                  child: Text(errorMessage!,
                      style: const TextStyle(color: Colors.red)),
                ),
              SizedBox(height: height / 55),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: height / 44, horizontal: width / 41),
                  child: ElevatedButton(
                    onPressed: () {
                      signIn();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8256DF),
                      padding: EdgeInsets.symmetric(
                          vertical: height / 56.33, horizontal: width / 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: Text(
                      'Giriş Yap',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: height / 50,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: height / 55),
              GestureDetector(
                onTap: () {
                  resetPassword();
                },
                child: Text(
                  "Şifremi Unuttum?",
                  style: TextStyle(
                    color: const Color(0xFF8256DF),
                    fontSize: height / 60,
                    fontFamily: "Poppins-Bold",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: height / 81),
              GestureDetector(
                child: Text.rich(
                  TextSpan(
                    text: "Henüz Hesabın Yok Mu? ",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: height / 60,
                        fontFamily: "Poppins-Bold",
                        fontWeight: FontWeight.w700),
                    children: [
                      TextSpan(
                        text: "Kayıt Ol 😊",
                        style: const TextStyle(
                          color: Color(0xFF8256DF),
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Register()),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
