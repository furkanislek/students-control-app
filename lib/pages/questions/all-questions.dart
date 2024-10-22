import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:students_follow_app/pages/questions/question-detail.dart';

class AllQuestions extends StatefulWidget {
  const AllQuestions({super.key});

  @override
  State<AllQuestions> createState() => _AllQuestionsState();
}

class _AllQuestionsState extends State<AllQuestions> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAllQuestions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
              crossAxisCount: 2, // Her satırda iki kart olacak
              crossAxisSpacing: 10, // Kartlar arası yatay boşluk
              mainAxisSpacing: 10, // Kartlar arası dikey boşluk
              childAspectRatio:
                  0.75, // Kartların yüksekliği (görsel tasarımı ayarlamak için)
            ),
            padding: const EdgeInsets.all(10),
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
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Görüntü var mı kontrolü
                        question['image'] != null
                            ? Image.memory(
                                Base64Decoder().convert(question['image']),
                                fit: BoxFit.fill,
                                height: 120, // Görüntünün yüksekliği
                                width: double.infinity,
                              )
                            : const SizedBox(
                                height: 120,
                                child:
                                    Placeholder()), // Placeholder (görsel yoksa)

                        const SizedBox(height: 8),

                        // Başlık
                        Text(
                          question['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Kategori ve tarih bilgisi
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('dd-MM-yyyy HH:mm').format(
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
