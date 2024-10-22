import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:students_follow_app/pages/Plans/plans.dart';

class SummaryProgress extends StatefulWidget {
  final int finishedLength;
  final int unFinishedLength;
  final int isCompletedLength;
  final int tasksLength;
  const SummaryProgress(
      {Key? key,
      required this.finishedLength,
      required this.unFinishedLength,
      required this.isCompletedLength,
      required this.tasksLength})
      : super(key: key);

  @override
  State<SummaryProgress> createState() => _SummaryProgressState();
}

class _SummaryProgressState extends State<SummaryProgress> {
  @override
  Widget build(BuildContext context) {
    final progressPercentage = widget.tasksLength > 0
        ? widget.isCompletedLength / widget.tasksLength
        : 0;
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 32.0, top: 15, bottom: 15),
      child: SizedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    CircularPercentIndicator(
                      radius: 70.0,
                      lineWidth: 13.0,
                      animation: true,
                      percent: progressPercentage.toDouble(),
                      center: Text(
                        "${(progressPercentage * 100).toStringAsFixed(1)}%",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                        ),
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: const Color(0xFF8256DF),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    Text(
                      '${widget.isCompletedLength} /  ${widget.tasksLength}',
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Tamamlanan\n Task Sayısı",
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ],
            ),
            Column(
              children: [
                IconButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TaskDetailsScreen()));
                    },
                    icon: const Icon(
                      Icons.add_circle_sharp,
                      fill: 0.5,
                      size: 50.5,
                      grade: -25,
                      color: Color(0xFF8256DF),
                    ))
              ],
            )
          ],
        ),
      ),
    );
  }
}
