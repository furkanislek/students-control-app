import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:students_follow_app/components/menu/menu.dart';
import 'package:uuid/uuid.dart';

class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late DateTime _selectedDate;
  late List<DateTime> _eventDates;
  final TextEditingController _titleContainer = TextEditingController();

  // Define categories
  final List<List<dynamic>> _categories = [
    [Icons.abc, 'Soru Çözümü'],
    [Icons.book, 'Kitap Okuma'],
    [Icons.coffee, 'Kahve Molası'],
    [Icons.video_label, 'Ders Tekrarı'],
    [Icons.quiz, 'Kaynak Araştırma'],
    [Icons.info_outline_sharp, 'Diğer'],
  ];

  // Track selected category
  String _selectedCategory = '';

  // Define time variables
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _resetSelectedDate();
  }

  void _resetSelectedDate() {
    _selectedDate = DateTime.now();
    _eventDates = [DateTime.now()];
  }

  String _formatDate(DateTime date) {
    return DateFormat("d MMMM, y", "tr_TR").format(date);
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select Time';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  // Function to pick time
  Future<void> _pickTime({required bool isStart}) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        if (isStart) {
          _startTime = pickedTime;
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  Future<void> _saveTaskToFirebase() async {
    // Firebase'e veriyi eklemek için bir referans oluşturuyoruz
    final FirebaseAuth auth = FirebaseAuth.instance;
    final String uid = auth.currentUser!.uid;
    var uuid = Uuid();

    DateTime startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime?.hour ?? 0,
      _startTime?.minute ?? 0,
    );

    DateTime endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime?.hour ?? 0,
      _endTime?.minute ?? 0,
    );
    // Veriyi yüklüyoruz
    await FirebaseFirestore.instance.collection('tasks').add({
      'date': _selectedDate,
      'title': _titleContainer.text,
      'category': _selectedCategory,
      'start_time': startDateTime,
      'end_time': endDateTime,
      'userId': uid,
      'createdDate': DateTime.now().millisecondsSinceEpoch,
      'taskId': uuid.v4(),
      'taskPoint': 10,
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hedef başarıyla kaydedildi')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final double width = size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hedef Ekle"),
        backgroundColor: const Color(0xFFF2F2F2),
      ),
      drawer: const Menu(),
      bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(10.0),
          child: ElevatedButton(
            onPressed: _saveTaskToFirebase,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8256DF),
              padding:
                  const EdgeInsets.symmetric(vertical: 15.0, horizontal: 100.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            child: const Text(
              'Planı Kaydet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          )),
      backgroundColor: const Color(0xFFF2F2F2),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Calendar Container
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(top: 20.0),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 0.0),
                              child: Text(
                                _formatDate(_selectedDate),
                                style: const TextStyle(
                                    color: Color(0xFF282625),
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "SF-Pro"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        CalendarTimeline(
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 4)),
                          eventDates: _eventDates,
                          onDateSelected: (date) =>
                              setState(() => _selectedDate = date),
                          dayNameColor: const Color(0xFF333A47),
                          activeDayColor: Colors.white,
                          activeBackgroundDayColor: const Color(0xFFA688E7),
                          selectableDayPredicate: (date) => date.day != 32,
                          locale: 'tr',
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      "Başlık",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF282625),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        TextField(
                          controller: _titleContainer,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: "Plan Başlığını Yazınız.",
                            hintStyle: TextStyle(
                                color: _titleContainer.text.isEmpty
                                    ? const Color.fromARGB(220, 168, 163, 161)
                                    : const Color(0xFF282625)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Category selection buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      "Kategoriler",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF282625),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: ChoiceChip(
                            showCheckmark: false,
                            avatarBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  0), // Remove circular border
                              side:
                                  BorderSide.none, // Make the border invisible
                            ),
                            avatar: Icon(_categories[index][0]), // Use IconData
                            label: Text(
                                _categories[index][1]), // Use String for label
                            labelStyle: TextStyle(
                              color: _selectedCategory == _categories[index][1]
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            selectedColor: const Color(0xFFA688E7),
                            backgroundColor: const Color(0xFFFFFFFF),
                            selected:
                                _selectedCategory == _categories[index][1],
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedCategory = _categories[index][1];
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: width / 2.2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Text("Başlangıç Saati",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF282625),
                              )),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _pickTime(isStart: true),
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(15.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              _startTime == null
                                  ? "Seçiniz"
                                  : _formatTime(_startTime),
                              style: const TextStyle(
                                color: Color(0xFF282625),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: width / 2.2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Text("Bitiş Saati",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF282625),
                              )),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _pickTime(isStart: false),
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(15.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              _endTime == null
                                  ? "Seçiniz"
                                  : _formatTime(_endTime),
                              style: const TextStyle(
                                color: Color(0xFF282625),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
