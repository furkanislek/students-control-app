import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:students_follow_app/pages/auth/login.dart';
import 'package:students_follow_app/services/auth.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? errorMessage;

  Future<void> registerUser() async {
    try {
      await Auth().registerUser(
        email: emailController.text,
        password: passwordController.text,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                "Maili Onayladın Mı? 😟",
                style: TextStyle(fontSize: 20),
              ),
              content: const Text("Onayladım 🎉?"),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("İptal"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Login()),
                    );
                  },
                  child: const Text("Onayla"),
                ),
              ],
            );
          },
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
              left: width / 13.7, right: width / 13.7, top: height / 17.8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: height / 74.17),
              Text(
                "Aramıza Hoşgeldin 🤗",
                style: TextStyle(
                    fontSize: height / 31,
                    fontFamily: "Poppins-Bold",
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: height / 40),
              SvgPicture.asset("assets/icons/register.svg", height: height / 3),
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
                      keyboardType: TextInputType.emailAddress,
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
                      vertical: height / 44, horizontal: width / 55),
                  child: ElevatedButton(
                    onPressed: () {
                      registerUser();
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
                      'Kayıt Ol',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: height / 50,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: height / 81),
              GestureDetector(
                child: Text.rich(
                  TextSpan(
                    text: "Hesabın Mevcut Mu ? ",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: height / 60,
                        fontFamily: "Poppins-Bold",
                        fontWeight: FontWeight.w700),
                    children: [
                      TextSpan(
                        text: "Giriş Yap 😊",
                        style: const TextStyle(
                          color: Color(0xFF8256DF),
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Login()),
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
