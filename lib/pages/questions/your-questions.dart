import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:students_follow_app/components/menu/menu.dart';
import 'package:students_follow_app/pages/questions/question-detail.dart';
import 'package:students_follow_app/utils/category-utils.dart';

class YourQuestions extends StatefulWidget {
  const YourQuestions({super.key});

  @override
  State<YourQuestions> createState() => _YourQuestionsState();
}

class _YourQuestionsState extends State<YourQuestions> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>?> _fetchUserQuestions() async {
    final String uid = _auth.currentUser!.uid;

    QuerySnapshot snapshot = await _firestore
        .collection('questions')
        .where('uid', isEqualTo: uid)
        .get();

    if (snapshot.docs.isEmpty) {
      return [];
    } else {
      List<Map<String, dynamic>> questions = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      questions.sort(
          (a, b) => (b['dateTime'] as Timestamp).compareTo(a['dateTime']));

      return questions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: const Text("Soruların"),
      ),
      drawer: const Menu(),
      body: FutureBuilder<List<Map<String, dynamic>>?>(
        future: _fetchUserQuestions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final questions = snapshot.data ?? [];

          if (questions.isEmpty) {
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SvgPicture.asset("assets/icons/login.svg", height: 300),
                const Text("Henüz Sorun Yok")
              ],
            ));
          }

          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuestionDetail(question: question),
                    ),
                  );
                },
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        question['image'] != null
                            ? Image.memory(
                                const Base64Decoder()
                                    .convert(question['image']),
                                fit: BoxFit.cover,
                                height: 220,
                                width: double.infinity,
                              )
                            : const SizedBox(
                                height: 100,
                                child: Placeholder()), // Placeholder

                        const SizedBox(height: 8),

                        Text(
                          question['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),
                        Text(
                          question['description'] ?? 'No Information',
                          style: const TextStyle(fontSize: 14),
                        ),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                             getCategoryString(question['category']),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              question['timestamp'] != null
                                  ? (question['timestamp'] as Timestamp)
                                      .toDate()
                                      .toString()
                                  : 'No Date',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
