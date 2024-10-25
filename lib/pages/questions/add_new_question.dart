import 'package:flutter/material.dart';
import 'package:Tudora/pages/questions/add-question.dart';
import 'package:Tudora/pages/questions/all-questions.dart';
import 'package:Tudora/pages/questions/your-questions.dart';

class AddNewQuestion extends StatefulWidget {
  const AddNewQuestion({super.key});

  @override
  State<AddNewQuestion> createState() => _AddNewQuestionState();
}

class _AddNewQuestionState extends State<AddNewQuestion> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF2F2F2),
          toolbarHeight: 60,
          title: const Text(
            "Sorular",
            style: TextStyle(
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
          bottom: const TabBar(
            indicatorColor: Colors.purple,
            labelColor: Colors.purple,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Soru Ekle", icon: Icon(Icons.add)),
              Tab(text: "Soruların", icon: Icon(Icons.question_answer)),
              Tab(text: "Tüm Sorular", icon: Icon(Icons.list)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AddNewQuestionPage(),
            YourQuestions(),
            AllQuestions(),
          ],
        ),
      ),
    );
  }
}
