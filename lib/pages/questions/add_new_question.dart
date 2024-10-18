import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:students_follow_app/components/menu/menu.dart';
import 'package:students_follow_app/pages/questions/question-enum.dart';
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
  QuestionCategory? _selectedCategory; // Store selected category

  @override
  void initState() {
    super.initState();
    var uuid = Uuid();
    questionId = uuid.v4(); // Create a random UUID
  }

  final TextEditingController _informationController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  String? _base64Image;

  Future<String?> pickAndCompressImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File imageFile = File(image.path);
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
        'category': categoryId, // Use category ID here
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
      _selectedCategory!.id, // Use the selected category ID
      _informationController.text,
      _titleController.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Soru başarıyla yüklendi.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Soru Ekle"),
      ),
      drawer: const Menu(),
      body: Padding(
          padding: const EdgeInsets.only(left: 30, right: 30),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset("assets/icons/info.svg", height: 300),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: DropdownButtonFormField<QuestionCategory>(
                      decoration: InputDecoration(
                        hintText: "Kategori Seçin",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                      ),
                      value: _selectedCategory,
                      items: QuestionCategory.values.map((category) {
                        return DropdownMenuItem<QuestionCategory>(
                          value: category,
                          child: Text(category.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      hintText: "-",
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Icon(Icons.title),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _informationController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      hintText: "-",
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Icon(Icons.description),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {
                        uploadQuestionImage();
                      },
                      child: const Text("Soru Görselini Yükle")),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {
                        uploadQuestionToFirestore();
                      },
                      child: const Text("Soruyu Yükle")),
                ),
              ],
            ),
          )),
    );
  }
}
