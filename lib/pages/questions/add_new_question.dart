import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:students_follow_app/pages/questions/add-question.dart';
import 'package:students_follow_app/pages/questions/all-questions.dart';
import 'package:students_follow_app/pages/questions/question-enum.dart';
import 'package:students_follow_app/pages/questions/your-questions.dart';
import 'package:students_follow_app/services/auth.dart';
import 'package:uuid/uuid.dart';

class AddNewQuestion extends StatefulWidget {
  const AddNewQuestion({super.key});

  @override
  State<AddNewQuestion> createState() => _AddNewQuestionState();
}

class _AddNewQuestionState extends State<AddNewQuestion> {
  String? questionId;
  List<Map<String, dynamic>> _userInfo = [];
  QuestionCategory? _selectedCategory;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    var uuid = Uuid();
    questionId = uuid.v4();
  }

  final TextEditingController _informationController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  String? _base64Image;

  Future<String?> pickAndCompressImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File imageFile = File(image.path);
      setState(() {
        _imageFile = imageFile;
      });
      String? base64Image = await compressAndConvertToBase64(imageFile);
      return base64Image;
    }
    return null;
  }

  Future<void> saveImageToFirestore(String? base64Image, int categoryId,
      String description, String title) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final String uid = auth.currentUser!.uid;
    var uuid = Uuid();

    try {
      await _fetchUserInfo();
      await FirebaseFirestore.instance.collection('questions').add({
        'uid': uid,
        'image': base64Image,
        'category': categoryId,
        'description': description,
        'title': title,
        'timestamp': FieldValue.serverTimestamp(),
        'dateTime': DateTime.now().millisecondsSinceEpoch,
        "questionId": uuid.v4(),
        "nickName": _userInfo[0]["nickName"]
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchUserInfo() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: Auth().currentUser?.uid)
        .get();

    List<Map<String, dynamic>> userInfo =
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    setState(() {
      _userInfo = userInfo;
    });
  }

  Future<String?> compressAndConvertToBase64(File imageFile) async {
    try {
      final List<int>? compressedImage =
          await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: 50,
      );

      if (compressedImage == null) {
        return null;
      }

      String base64Image = base64Encode(compressedImage);
      return base64Image;
    } catch (e) {
      return null;
    }
  }

  void uploadQuestionImage() async {
    String? base64Image = await pickAndCompressImage();

    if (base64Image != null) {
      setState(() {
        _base64Image = base64Image;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Görsel başarıyla yüklendi.")),
      );
    }
  }

  void uploadQuestionToFirestore() async {
    if (_base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lütfen önce bir görsel yükleyin.")),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lütfen bir kategori seçin.")),
      );
      return;
    }

    await saveImageToFirestore(
      _base64Image,
      _selectedCategory!.id,
      _informationController.text,
      _titleController.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Soru başarıyla yüklendi.")),
    );

    setState(() {
      _base64Image = null;
      _imageFile = null;
      _informationController.clear();
      _titleController.clear();
      _selectedCategory = null;
    });
  }

  void _selectCategory(QuestionCategory category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  Widget _buildImageButtonOrImage() {
    if (_base64Image != null && _imageFile != null) {
      return GestureDetector(
        onTap: uploadQuestionImage,
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 2),
            borderRadius: BorderRadius.circular(15.0),
            image: DecorationImage(
              image: FileImage(_imageFile!),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        height: 150,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: uploadQuestionImage,
          icon: const Icon(Icons.image),
          label: const Text("Görsel Yükle"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: const BorderSide(
                    width: 1,
                    style: BorderStyle.solid,
                    color: Color.fromARGB(134, 66, 5, 77))),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF2F2F2),
          toolbarHeight: 60,
          title: const Text(
            "Sorular",
            style: TextStyle(
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
          bottom: const TabBar(
            indicatorColor: Colors.purple,
            labelColor: Colors.purple,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Soru Ekle", icon: Icon(Icons.add)),
              Tab(text: "Soruların", icon: Icon(Icons.question_answer)),
              Tab(text: "Tüm Sorular", icon: Icon(Icons.list)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AddNewQuestionPage(),
            YourQuestions(),
            AllQuestions(),
          ],
        ),
      ),
    );
  }
}
