import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:Tudora/pages/Leaderboard/leaderboard.dart';
import 'package:Tudora/pages/Profile/profile.dart';
import 'package:Tudora/pages/home/home.dart';
import 'package:Tudora/pages/questions/add_new_question.dart';
import 'package:Tudora/pages/questions/quiz/quiz-page.dart';
import 'package:Tudora/services/auth.dart';

class MenuHome extends StatefulWidget {
  const MenuHome({super.key});

  @override
  State<MenuHome> createState() => _MenuHomeState();
}

class _MenuHomeState extends State<MenuHome> {
  int _pageIndex = 2;
  String userID = "";
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    userID = Auth().currentUser!.uid;
    _pages = [
      LeaderboardPage(),
      Profile(userID: userID),
      const Home(),
      const AddNewQuestion(),
      QuizPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_pageIndex],
      bottomNavigationBar: CurvedNavigationBar(
        animationDuration: const Duration(milliseconds: 500),
        index: 2,
        backgroundColor: const Color(0xFFF2F2F2),
        height: 60,
        color: Color(0xFF8256DF),
        items: const <Widget>[
          Icon(Icons.leaderboard, size: 30),
          Icon(Icons.person, size: 30),
          Icon(Icons.home, size: 30),
          Icon(Icons.question_mark, size: 30),
          Icon(Icons.quiz, size: 30),
        ],
        onTap: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
      ),
    );
  }
}
