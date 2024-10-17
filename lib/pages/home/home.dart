import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:students_follow_app/pages/auth/login_register_page.dart';
import 'package:students_follow_app/questions/add_new_question.dart';
import 'package:students_follow_app/questions/all-questions.dart';
import 'package:students_follow_app/questions/your-questions.dart';
import 'package:students_follow_app/services/auth.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  String? errorMessage;
  String? nickname;
  String? name;

  // Başlıklar için liste
  static const List<String> _titles = [
    'Soru Ekle',
    'Soruların',
    'Tüm Sorular',
  ];

  @override
  void initState() {
    super.initState();
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

  // Alt menüdeki sayfalar
  static const List<Widget> _pages = <Widget>[
    AddNewQuestion(),
    YourQuestions(),
    AllQuestions(),
  ];

  // Sayfa seçimi
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Dinamik başlık
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: signOut, // Çıkış yapma işlemi
          ),
        ],
      ),
      body: Center(
        child: _pages.elementAt(_selectedIndex), // Seçilen sayfa gösterilecek
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Soru Ekle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.question_answer),
            label: 'Soruların',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Tüm Sorular',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped, // Menü öğesine tıklandığında çağrılacak fonksiyon
      ),
    );
  }
}
