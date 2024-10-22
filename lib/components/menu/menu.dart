import 'package:flutter/material.dart';
import 'package:students_follow_app/pages/Leaderboard/leaderboard.dart';
import 'package:students_follow_app/pages/auth/login_register_page.dart';
import 'package:students_follow_app/pages/home/home.dart';
import 'package:students_follow_app/pages/questions/add_new_question.dart';
import 'package:students_follow_app/pages/questions/quiz/quiz-page.dart';
import 'package:students_follow_app/services/auth.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  int _currentIndex = 0;
  String? errorMessage;
  String? userID;
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
          userName = userInfos[0]['name'];
          userID = userInfos[0]["uid"];
          isLoading = false;
        });
      } else {
        setState(() {
          userName = "";
          userID = "";
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

  Future<void> signOut() async {
    try {
      await Auth().signOut();
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const LoginRegisterPage()));
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  // Alt menüde göstermek istediğiniz sayfalar
  final List<Widget> _pages = [
    const Home(),
    const AddNewQuestion(), // Sorular menüsü altında sadece "Soru Ekle"
    QuizPage(),
    const LeaderboardPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLoading ? 'Yükleniyor...' : userName),
        backgroundColor: const Color.fromARGB(255, 186, 104, 200),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Soru Ekle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Sıralama',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
