import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:students_follow_app/components/menu/menu.dart';
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
    _tabController?.dispose(); // TabController'ı yok et
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
    // Kullanıcının UID'sini al
    final user = _auth.currentUser;
    if (user == null) return;

    // Firestore'dan görevleri al
    final tasks = await _firestore
        .collection('tasks')
        .where('userId', isEqualTo: user.uid)
        .get();

    final now = DateTime.now();

    // Her bir görev için durumları kontrol et
    for (var doc in tasks.docs) {
      final taskData = doc.data();

      // Zaman damgalarını DateTime'a dönüştür
      final endDate = (taskData['end_time'] as Timestamp).toDate();
      final startDate = (taskData['start_time'] as Timestamp).toDate();

      // Hata ayıklama için tarihleri yazdır
      print("Şu anki zaman: $now");
      print("Bitiş zamanı: $endDate");
      print("Başlangıç zamanı: $startDate");

      if (endDate.isBefore(now)) {
        // Süresi dolmuş
        _expiredTasks.add(taskData);
      } else if (startDate.isBefore(now) && endDate.isAfter(now)) {
        // Şu anda aktif olan
        _activeTasks.add(taskData);
      } else if (startDate.isAfter(now)) {
        // Gelecekte başlayacak
        _upcomingTasks.add(taskData);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
      drawer: const Menu(),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Diğer bir başlık veya bileşen ekleyebilirsiniz.',
              style: TextStyle(fontSize: 18),
            ),
          ),
          TabBar(
            controller: _tabController, // TabController ile ilişkilendir
            indicatorColor: Colors.purple,
            labelColor: Colors.purple,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Süresi Dolmuş"),
              Tab(text: "Aktif Olan"),
              Tab(text: "Gelecek"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller:
                  _tabController, // TabBarView ile TabController'ı bağla
              children: [
                _buildTaskList(_expiredTasks, Colors.redAccent),
                _buildTaskList(_activeTasks, Colors.green),
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
      return 0; // Gelecek görevler için ilerleme 0
    } else if (currentTime > endDate) {
      return 100; // Bitmiş görevler için ilerleme 100
    } else {
      // Aktif görevler için ilerlemeyi hesapla
      return ((currentTime - startDate) * 100 / (endDate - startDate))
          .clamp(0, 100);
    }
  }

  Widget _buildTaskTile(Map<String, dynamic> task, Color color) {
    // StartDate ve EndDate'in null olup olmadığını kontrol ediyoruz

    final Timestamp? startTimestamp = task['start_time'] as Timestamp?;
    final Timestamp? endTimestamp = task['end_time'] as Timestamp?;
    final int currentTime = DateTime.now().millisecondsSinceEpoch;

    final int startDate = startTimestamp!.millisecondsSinceEpoch;
    final int endDate = endTimestamp!.millisecondsSinceEpoch;

    final int remainingTime = endDate - currentTime;
    final int hours = (remainingTime ~/ (1000 * 60 * 60)).abs(); // Saat
    final int minutes = (remainingTime ~/ (1000 * 60)).abs() % 60; // Dakika
    // Process yüzdesi hesaplama
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

      // Kategoriye göre uygun ikonu döndür
      for (var item in _categories) {
        if (item[1] == category) {
          return item[0]; // İkonu döndür
        }
      }

      return Icons.help; // Eğer kategori bulunamazsa varsayılan ikon
    }

    IconData taskIcon = _getCategoryIcon(task['category']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(taskIcon, color: color),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(task['title']),
              Text(
                "$hours Saat $minutes Dakika", // Kalan süreyi saat ve dakika cinsinden göster
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Kategori: ${task['category']}"),
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.center, // Yüzdeyi ortalamak için
                children: [
                  LinearProgressIndicator(
                    value: progressPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    minHeight: 20,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  Text(
                    "${progressPercentage.toStringAsFixed(2)}%", // İlerleme yüzdesini yazdır
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold), // Yazı rengi
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
