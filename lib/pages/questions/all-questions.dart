import 'dart:convert';
import 'package:Tudora/components/loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Tudora/pages/questions/question-detail.dart';

class AllQuestions extends StatefulWidget {
  const AllQuestions({super.key});

  @override
  State<AllQuestions> createState() => _AllQuestionsState();
}

class _AllQuestionsState extends State<AllQuestions> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var commentCount = 0;

  Future<List<Map<String, dynamic>>> _fetchAllQuestions() async {
    QuerySnapshot snapshot = await _firestore
        .collection('questions')
        .orderBy('dateTime', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.sizeOf(context).height;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAllQuestions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingScreen());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final questions = snapshot.data ?? [];

          if (questions.isEmpty) {
            return const Center(child: Text('No questions found.'));
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            padding: const EdgeInsets.all(5),
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
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 1, horizontal: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        question['image'] != null
                            ? Image.memory(
                                Base64Decoder().convert(question['image']),
                                fit: BoxFit.fill,
                                height: height / 7.42,
                                width: double.infinity,
                              )
                            : SizedBox(
                                height: height / 7.42, child: Placeholder()),
                        Text(
                          question['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('d MMMM yyyy', 'tr_TR').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      question['dateTime'])),
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
