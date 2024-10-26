import 'dart:convert';
import 'package:Tudora/components/loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:Tudora/pages/questions/question-detail.dart';
import 'package:Tudora/utils/category-utils.dart';
import 'package:intl/intl.dart';

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

      questions.sort((a, b) => (b['dateTime']).compareTo(a['dateTime']));

      return questions;
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.sizeOf(context).height;
    double width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: const Color(0xfff2f2f2),
      body: FutureBuilder<List<Map<String, dynamic>>?>(
        future: _fetchUserQuestions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingScreen());
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
                SvgPicture.asset("assets/icons/login.svg", height: height / 30),
                const Text("Henüz Sorun Yok")
              ],
            ));
          }

          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              print(" question['timestamp'] ${question['timestamp']}");

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
                  margin: EdgeInsets.symmetric(
                      vertical: height / 89, horizontal: width / 27.4),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        question['image'] != null
                            ? Image.memory(
                                const Base64Decoder()
                                    .convert(question['image']),
                                fit: BoxFit.cover,
                                height: height / 4.045,
                                width: double.infinity,
                              )
                            : SizedBox(
                                height: height / 8.9, child: Placeholder()),
                        SizedBox(height: height / 111),
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
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
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
                              question['dateTime'] != null
                                  ? DateFormat("d MMMM y - HH:mm", "tr_TR")
                                      .format(
                                          DateTime.fromMillisecondsSinceEpoch(
                                                  question['dateTime'])
                                              .add(const Duration(hours: 3)))
                                  : '',
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
