import 'package:Tudora/pages/home/menu-home.dart';
import 'package:Tudora/services/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timer_countdown/flutter_timer_countdown.dart';
import 'package:vibration/vibration.dart';

class Timer extends StatefulWidget {
  final Color color;
  final int timer;
  const Timer({Key? key, required this.color, required this.timer})
      : super(key: key);

  @override
  State<Timer> createState() => _TimerState();
}

class _TimerState extends State<Timer> {
  late ConfettiController _confettiController;
  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

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

      _confettiController.play();
      vibrate();
      Future.delayed(const Duration(seconds: 10), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MenuHome()),
          (route) => false,
        );
      });
    }
  }

  static Future<void> vibrate() async {
    await SystemChannels.platform.invokeMethod<void>('HapticFeedback.vibrate');
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
      body: Stack(children: [
        Center(
          child: CupertinoPageScaffold(
            backgroundColor: widget.color,
            child: TimerCountdown(
              colonsTextStyle: const TextStyle(fontSize: 72),
              format: CountDownTimerFormat.minutesSeconds,
              minutesDescription: "Dakika",
              secondsDescription: "Saniye",
              timeTextStyle: const TextStyle(fontSize: 40),
              descriptionTextStyle: const TextStyle(fontSize: 40),
              endTime: DateTime.now().add(
                Duration(
                  minutes: widget.timer,
                ),
              ),
              onEnd: () async {
                if (widget.timer > 60) {
                  await updateUserPoints(
                      ((((widget.timer) / 30) * 25) - 25) as int);
                } else {
                  await updateUserPoints(25);
                }
                if (await Vibration.hasVibrator() ?? false) {
                  Vibration.vibrate(
                      duration: 1500); 
                }
                HapticFeedback.vibrate();
              },
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
        )
      ]),
    );
  }
}
