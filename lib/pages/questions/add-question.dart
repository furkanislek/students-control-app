import 'dart:convert';
import 'dart:io';
import 'package:Tudora/pages/questions/your-questions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Tudora/pages/questions/question-enum.dart';
import 'package:Tudora/services/auth.dart';
import 'package:Tudora/utils/category-utils.dart';
import 'package:uuid/uuid.dart';

class AddNewQuestionPage extends StatefulWidget {
  const AddNewQuestionPage({super.key});

  @override
  State<AddNewQuestionPage> createState() => _AddNewQuestionPageState();
}

class _AddNewQuestionPageState extends State<AddNewQuestionPage> {
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

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const YourQuestions()),
        (route) => false,
      );
    });

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

  Widget _buildImageButtonOrImage(double heightTop) {
    if (_base64Image != null && _imageFile != null) {
      return GestureDetector(
        onTap: uploadQuestionImage,
        child: Container(
          height: heightTop,
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
        height: heightTop,
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
                    color: const Color.fromARGB(134, 66, 5, 77))),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.sizeOf(context).height;
    double width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      bottomNavigationBar: Padding(
          padding: EdgeInsets.symmetric(
              vertical: height / 44.5, horizontal: width / 41.1),
          child: ElevatedButton.icon(
            onPressed: uploadQuestionToFirestore,
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8256DF),
              padding: EdgeInsets.symmetric(
                  vertical: height / 59.33, horizontal: width / 4.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            label: const Text(
              'Soruyu Yükle',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          )),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: height / 90),
              _buildImageButtonOrImage(height / 5.95),
              SizedBox(height: height / 44.5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  SizedBox(height: height / 59.33),
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
                        SizedBox(height: height / 89),
                        SizedBox(
                          height: height / 22.5,
                          child: TextField(
                            controller: _titleController,
                            textInputAction: TextInputAction.done,
                            keyboardType: TextInputType.text,
                            maxLength: 35,
                            decoration: InputDecoration(
                              hintText: "Soru Başlığını Yazınız.",
                              hintStyle: TextStyle(
                                  color: _titleController.text.isEmpty
                                      ? const Color.fromARGB(220, 168, 163, 161)
                                      : const Color(0xFF282625)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: height / 59.33),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      "Soru Detayı",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF282625),
                      ),
                    ),
                  ),
                  SizedBox(height: height / 89),
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
                          controller: _informationController,
                          textInputAction: TextInputAction.done,
                          minLines: 2,
                          maxLines: 2,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: "Soruyu Yazınız.",
                            hintStyle: TextStyle(
                                color: _informationController.text.isEmpty
                                    ? const Color.fromARGB(220, 168, 163, 161)
                                    : const Color(0xFF282625)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: height / 44.5),
              SizedBox(
                height: height / 19.78,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: QuestionCategory.values.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(right: width / 34),
                      child: ChoiceChip(
                        showCheckmark: false,
                        avatarBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                          side: BorderSide.none,
                        ),
                        label: Text(getCategoryString(
                            QuestionCategory.values[index].index)),
                        labelStyle: TextStyle(
                          color: _selectedCategory ==
                                  QuestionCategory.values[index]
                              ? Colors.white
                              : Colors.black,
                        ),
                        selectedColor: const Color(0xFFA688E7),
                        backgroundColor: const Color(0xFFFFFFFF),
                        selected:
                            _selectedCategory == QuestionCategory.values[index],
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedCategory = QuestionCategory.values[index];
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
