import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:students_follow_app/pages/Plans/plans.dart';
import 'package:students_follow_app/pages/Profile/profile.dart';
import 'package:students_follow_app/pages/auth/login_register_page.dart';
import 'package:students_follow_app/pages/home/home.dart';
import 'package:students_follow_app/pages/questions/add_new_question.dart';
import 'package:students_follow_app/pages/questions/all-questions.dart';
import 'package:students_follow_app/pages/questions/your-questions.dart';
import 'package:students_follow_app/services/auth.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  String? errorMessage;
  String? profileImage;
  String userName = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    try {
      final userInfos = await Auth().fetchUserInfo();
      if (userInfos != null && userInfos.isNotEmpty) {
        setState(() {
          profileImage = userInfos[0]['profileImage'];
          userName = userInfos[0]['name'];
          isLoading = false;
        });
      } else {
        setState(() {
          profileImage = null;
          userName = "";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Future<void> signOut() async {
    try {
      await Auth().signOut();
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const LoginRegisterPage()));
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Uint8List? decodeBase64Image(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null; // Hata durumunda null döner
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 186, 104, 200),
            ),
            child: GestureDetector(
              child: isLoading
                  ? const CircularProgressIndicator() // Yükleniyor göstergesi
                  : Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Profile()));
                          },
                          child: CircleAvatar(
                            backgroundImage: profileImage != null
                                ? MemoryImage(decodeBase64Image(
                                    profileImage!)!) // Profil resmi varsa
                                : const AssetImage(
                                    "assets/icons/unknow.svg"), // Varsayılan resim
                            radius: 40, // Çemberin yarıçapı
                          ),
                        ),
                        const SizedBox(
                            width: 16), // Çember ile metin arasında boşluk
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Home()));
                          },
                          child: Text(
                            userName,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 21, 3, 32),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent), // Divider'ı kaldırmak için
            child: ExpansionTile(
              leading: const Icon(Icons.question_mark),
              title: const Text('Sorular'),
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.add_box),
                  title: const Text('Soru Ekle'),
                  contentPadding: const EdgeInsets.only(left: 32.0),
                  onTap: () {
                    _navigateToPage(context, const AddNewQuestion());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.question_answer),
                  title: const Text('Soruların'),
                  contentPadding: const EdgeInsets.only(left: 32.0),
                  onTap: () {
                    _navigateToPage(context, const YourQuestions());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text('Tüm Sorular'),
                  contentPadding: const EdgeInsets.only(left: 32.0),
                  onTap: () {
                    _navigateToPage(context, const AllQuestions());
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Takip'),
            onTap: () {
              _navigateToPage(context, const Plans());
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil Bilgilerim'),
            onTap: () {
              _navigateToPage(context, const Profile());
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Çıkış Yap"),
            onTap: () {
              signOut();
            },
          )
        ],
      ),
    );
  }
}
