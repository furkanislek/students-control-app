import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
        .orderBy('dateTime', descending: true) // En yeni sorular en üstte
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Questions'),
      ),
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

          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      question['image'] != null
                          ? Image.memory(
                              Base64Decoder().convert(question['image']),
                              fit: BoxFit.cover,
                            )
                          : const SizedBox(
                              height: 100, child: Placeholder()), // Placeholder

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
                            question['category'] ?? 'No Category',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            DateTime.fromMillisecondsSinceEpoch(
                                    question['dateTime'])
                                .toString(),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
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
