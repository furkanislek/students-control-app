import 'package:Tudora/pages/home/menu-home.dart';
import 'package:Tudora/services/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timer_countdown/flutter_timer_countdown.dart';

class Timer extends StatefulWidget {
  final Color color;
  final int timer;
  const Timer({Key? key, required this.color, required this.timer})
      : super(key: key);

  @override
  State<Timer> createState() => _TimerState();
}

class _TimerState extends State<Timer> {
  Future<void> updateUserPoints(int points) async {
    var docRef = await FirebaseFirestore.instance
        .collection("users")
        .where("uid", isEqualTo: Auth().currentUser!.uid)
        .limit(1)
        .get();

    if (docRef.docs.isNotEmpty) {
      var userDoc = docRef.docs.first;

      await userDoc.reference.update({
        "userPoint": FieldValue.arrayUnion([
          {
            'dateTime': DateTime.now().millisecondsSinceEpoch,
            "userPoint": points,
            "questionId": "targetAlarms",
          }
        ])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print(widget.timer);
    return Scaffold(
      backgroundColor: widget.color,
      appBar: AppBar(
        backgroundColor: widget.color,
        title: const Text(""),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Emin Misin?"),
                      content: const Center(
                          child: Text(
                              "Eğer çıkarsan puan alamayacaksın ! Pes Etmek Yok 🙏")),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const MenuHome()),
                              );
                            },
                            child: const Text("Eminim 😟")),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("İptal"),
                        )
                      ],
                    );
                  });
            },
          ),
        ],
      ),
      body: Center(
        child: CupertinoPageScaffold(
          backgroundColor: widget.color,
          child: TimerCountdown(
            colonsTextStyle: const TextStyle(fontSize: 72),
            format: CountDownTimerFormat.minutesSeconds,
            endTime: DateTime.now().add(
              Duration(
                minutes: widget.timer,
              ),
            ),
            onEnd: () {
              if (widget.timer > 60) {
                updateUserPoints((((widget.timer) / 60) * 100) as int);
              } else {
                updateUserPoints(100);
              }
            },
          ),
        ),
      ),
    );
  }
}
