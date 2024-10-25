import 'package:Tudora/pages/home/menu-home.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gradient_app_bar/flutter_gradient_app_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:Tudora/services/auth.dart';

class QuizPage extends StatefulWidget {
  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Map<String, dynamic>> questions = [];
  Map<String, String> selectedAnswers = {};
  String? quizId;
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  int currentQuestionIndex = 0;
  bool isExecuted = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    fetchActiveQuiz();
    checkIsExcecuted();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> fetchActiveQuiz() async {
    QuerySnapshot quizSnapshot =
        await FirebaseFirestore.instance.collection('quiz').get();
    DateTime now = DateTime.now();

    final userInfo = await Auth().fetchUserInfoByUid(Auth().currentUser!.uid);
    final userPoints = userInfo![0]["userPoint"] ?? [];

    for (var doc in quizSnapshot.docs) {
      Map<String, dynamic>? quizData = doc.data() as Map<String, dynamic>?;

      if (quizData != null) {
        Timestamp startTimestamp = quizData['startDate'];
        Timestamp endTimestamp = quizData['endDate'];
        DateTime startDate = startTimestamp.toDate();
        DateTime endDate = endTimestamp.toDate();
        if (now.isAfter(startDate) && now.isBefore(endDate)) {
          for (var item in userPoints) {
            if (item["questionId"] == quizData["quizId"]) {
              setState(() {
                isExecuted = true;
              });
              break;
            }
          }
          setState(() {
            questions = List<Map<String, dynamic>>.from(quizData['question']);
            quizId = quizData["quizId"];
          });
        } else {
          setState(() {
            isExecuted = true;
          });
        }
      }
    }
  }

  Future<void> checkIsExcecuted() async {
    try {
      final userInfo = await Auth().fetchUserInfoByUid(Auth().currentUser!.uid);
      final userPoints = userInfo![0]["userPoint"] ?? [];

      if (quizId != null) {
        for (var item in userPoints) {
          if (item["questionId"] == quizId) {
            setState(() {
              isExecuted = true;
            });
            break;
          }
        }
      }
    } catch (e) {
      print("Execute yaparken sorun oldu: $e");
    }
  }

  Future<void> submitAnswer(String questionId, String selectedAnswer,
      String correctAnswer, int points) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcı bulunamadı. Lütfen giriş yapın.')),
      );
      return;
    }

    bool isCorrect = selectedAnswer == correctAnswer;

    setState(() {
      selectedAnswers[questionId] = selectedAnswer;
    });

    if (isCorrect) {
      await updateUserPoints(points);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isCorrect ? 'Doğru cevap!' : 'Yanlış cevap!')),
    );

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      await submitAllAnswers();
    }
  }

  Future<void> updateUserPoints(int points) async {
    var docRef = await FirebaseFirestore.instance
        .collection("users")
        .where("uid", isEqualTo: userId)
        .limit(1)
        .get();

    if (docRef.docs.isNotEmpty) {
      var userDoc = docRef.docs.first;

      await userDoc.reference.update({
        "userPoint": FieldValue.arrayUnion([
          {
            'dateTime': DateTime.now().millisecondsSinceEpoch,
            "userPoint": points,
            "questionId": quizId,
          }
        ])
      });
    }
  }

  Future<void> submitAllAnswers() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tüm cevaplarınız gönderildi!')),
    );

    _confettiController.play();

    Future.delayed(const Duration(seconds: 15), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MenuHome()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: const Text('Quiz'),
        gradient: const LinearGradient(
          colors: [
            Colors.cyan,
            Colors.indigo,
          ],
        ),
      ),
      body: Stack(
        children: [
          isExecuted
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Testi Çözdüğün İçin Teşekkürler 🤗 \nBir Sonraki Quizde Başarılar 🎉",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SvgPicture.asset(
                        'assets/quiz/quiz.svg',
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Color(0xFF2196F3),
                          Color(0xFFF44336),
                        ],
                      ),
                    ),
                    child: questions.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : Card(
                            margin: const EdgeInsets.all(10),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    questions[currentQuestionIndex]
                                            ['questionText'] ??
                                        'Soru yok',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 25),
                                  ...((questions[currentQuestionIndex]
                                          ['answers'] as Map<String, dynamic>)
                                      .entries
                                      .map((entry) {
                                    String answerKey = entry.key;
                                    String answerValue = entry.value;
                                    bool isSelected = selectedAnswers[
                                            questions[currentQuestionIndex]
                                                ['questionId']] ==
                                        answerValue;

                                    return SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isSelected
                                              ? (answerValue ==
                                                      questions[
                                                              currentQuestionIndex]
                                                          ['correctAnswer']
                                                  ? Colors.green
                                                  : Colors.red)
                                              : const Color.fromARGB(
                                                  255, 255, 254, 254),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                        ),
                                        onPressed: () {
                                          if (selectedAnswers[questions[
                                                      currentQuestionIndex]
                                                  ['questionId']] ==
                                              null) {
                                            submitAnswer(
                                              questions[currentQuestionIndex]
                                                  ['questionId'],
                                              answerValue,
                                              questions[currentQuestionIndex]
                                                  ['correctAnswer'],
                                              questions[currentQuestionIndex]
                                                  ['points'],
                                            );
                                          }
                                        },
                                        child: Text('$answerKey: $answerValue'),
                                      ),
                                    );
                                  })).toList(),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 50,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }
}
