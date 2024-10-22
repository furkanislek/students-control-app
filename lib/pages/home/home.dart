import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:students_follow_app/components/home/summary-progress.dart';
import 'package:students_follow_app/pages/auth/login_register_page.dart';
import 'package:students_follow_app/services/auth.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String? errorMessage;
  var isCompletedLength = 0;
  var tasksLength = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _expiredTasks = [];
  List<Map<String, dynamic>> _activeTasks = [];
  List<Map<String, dynamic>> _upcomingTasks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTasks();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> signOut() async {
    try {
      await Auth().signOut();
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const LoginRegisterPage()));
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> _fetchTasks() async {
    isCompletedLength = 0;
    final user = _auth.currentUser;
    if (user == null) return;

    final tasks = await _firestore
        .collection('tasks')
        .where('userId', isEqualTo: user.uid)
        .get();
    final now = DateTime.now();
    print(tasks.docs.length);
    for (var doc in tasks.docs) {
      print(doc.data());
      final taskData = doc.data();

      if (taskData["isCompleted"]) {
        setState(() {
          isCompletedLength++;
        });
      }

      final endDate = (taskData['end_time'] as Timestamp).toDate();
      final startDate = (taskData['start_time'] as Timestamp).toDate();

      if (endDate.isBefore(now)) {
        _expiredTasks.add(taskData);
      } else if (startDate.isBefore(now) && endDate.isAfter(now)) {
        _activeTasks.add(taskData);
      } else if (startDate.isAfter(now)) {
        _upcomingTasks.add(taskData);
      }
    }

    setState(() {
      tasksLength = tasks.docs.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final finishedLength = _expiredTasks.length;
    final unFinishedLength = _activeTasks.length + _upcomingTasks.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Görevler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: signOut,
          ),
        ],
      ),
      backgroundColor: Color.fromARGB(0, 7, 7, 196),
      body: Column(
        children: [
          Padding(
              padding: const EdgeInsets.all(0.0),
              child: SummaryProgress(
                  finishedLength: finishedLength,
                  unFinishedLength: unFinishedLength,
                  isCompletedLength: isCompletedLength,
                  tasksLength: tasksLength)),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.purple,
            labelColor: Colors.purple,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Süresi Dolmuş"),
              Tab(text: "Aktif Olan"),
              Tab(text: "Gelecek"),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(
                    _expiredTasks, const Color.fromARGB(255, 224, 104, 67)),
                _buildTaskList(
                    _activeTasks, const Color.fromARGB(255, 131, 185, 119)),
                _buildTaskList(_upcomingTasks, Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Map<String, dynamic>> tasks, Color color) {
    return tasks.isNotEmpty
        ? ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _buildTaskTile(task, color);
            },
          )
        : const Center(child: Text('Bu kategoride görev yok'));
  }

  double _calculateProgress(int currentTime, int startDate, int endDate) {
    if (currentTime < startDate) {
      return 0;
    } else if (currentTime > endDate) {
      return 100;
    } else {
      return ((currentTime - startDate) * 100 / (endDate - startDate))
          .clamp(0, 100);
    }
  }

  Future<void> _updateTaskCompletion(String taskId, bool isCompleted) async {
    try {
      var docRef = await _firestore
          .collection("tasks")
          .where("taskId", isEqualTo: taskId)
          .limit(1)
          .get();

      if (docRef.docs.isNotEmpty) {
        var taskDoc = docRef.docs.first;
        await taskDoc.reference.update({"isCompleted": !isCompleted});
      } else {
        print("Task Bulunamadı");
      }

      setState(() {
        _expiredTasks.clear();
        _activeTasks.clear();
        _upcomingTasks.clear();
      });
      await _fetchTasks();
    } catch (e) {
      print("Görevi güncellerken hata: $e");
    }
  }

  Widget _buildTaskTile(Map<String, dynamic> task, Color color) {
    final Timestamp? startTimestamp = task['start_time'] as Timestamp?;
    final Timestamp? endTimestamp = task['end_time'] as Timestamp?;
    final int currentTime = DateTime.now().millisecondsSinceEpoch;

    final int startDate = startTimestamp!.millisecondsSinceEpoch;
    final int endDate = endTimestamp!.millisecondsSinceEpoch;

    final int remainingTime = endDate - currentTime;
    final int hours = (remainingTime ~/ (1000 * 60 * 60)).abs();
    final int minutes = (remainingTime ~/ (1000 * 60)).abs() % 60;
    double progressPercentage =
        _calculateProgress(currentTime, startDate, endDate);

    IconData _getCategoryIcon(String category) {
      final List<List<dynamic>> _categories = [
        [Icons.abc, 'Soru Çözümü'],
        [Icons.book, 'Kitap Okuma'],
        [Icons.coffee, 'Kahve Molası'],
        [Icons.video_label, 'Ders Tekrarı'],
        [Icons.quiz, 'Kaynak Araştırma'],
        [Icons.info_outline_sharp, 'Diğer'],
      ];

      for (var item in _categories) {
        if (item[1] == category) {
          return item[0];
        }
      }

      return Icons.help;
    }

    IconData taskIcon = _getCategoryIcon(task['category']);

    final bool isCompleted = task['isCompleted'] ?? false;
    final Color cardColor = isCompleted
        ? const Color.fromARGB(255, 0, 107, 23)
        : const Color.fromARGB(255, 187, 170, 170);
    final Color iconColor =
        isCompleted ? Color.fromARGB(255, 131, 185, 119) : color;

    return Dismissible(
      key: Key(task['taskId']),
      background: Container(
        color: !isCompleted
            ? const Color.fromARGB(255, 131, 185, 119)
            : Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        child:
            Icon(!isCompleted ? Icons.check : Icons.undo, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: !isCompleted
            ? const Color.fromARGB(255, 131, 185, 119)
            : const Color(0xFFEB7E5C),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child:
            Icon(!isCompleted ? Icons.check : Icons.undo, color: Colors.white),
      ),
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await _updateTaskCompletion(task['taskId'], isCompleted);
        } else if (direction == DismissDirection.startToEnd) {
          await _updateTaskCompletion(task['taskId'], isCompleted);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cardColor,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    const Color.fromARGB(255, 255, 255, 255).withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İlk satır: İkon, Başlık, Süre
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(taskIcon, color: iconColor),
                        const SizedBox(width: 8),
                        Text(task['title'],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(
                      "$hours Saat $minutes Dakika",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // İkinci satır: Kategori
                Text("Kategori: ${task['category']}"),
                const SizedBox(height: 8),
                // Üçüncü satır: Progress Bar genişliği %100
                SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      LinearProgressIndicator(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20)),
                        value: progressPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        minHeight: 20,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                      Text(
                        "${progressPercentage.toStringAsFixed(2)}%",
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
