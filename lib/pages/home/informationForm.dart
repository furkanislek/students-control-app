import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:Tudora/pages/home/home.dart';
import 'package:uuid/uuid.dart';

class InformationForm extends StatefulWidget {
  const InformationForm({super.key});

  @override
  State<InformationForm> createState() => _InformationFormState();
}

class _InformationFormState extends State<InformationForm> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nickNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  DateTime? selectedDate;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  String? _base64Image;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _base64Image = await _compressAndConvertToBase64(_image!);
    }
  }

  Future<String?> _compressAndConvertToBase64(File imageFile) async {
    try {
      final List<int>? compressedImage =
          await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: 50,
      );

      if (compressedImage == null) {
        return null;
      }

      return base64Encode(compressedImage);
    } catch (e) {
      print("Resim sıkıştırma hatası: $e");
      return null;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale("tr"),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _dateController.text =
            DateFormat('d MMMM yyyy', 'tr_TR').format(selectedDate!);
      });
    }
  }

  Future<void> _saveToFirestore() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final String uid = auth.currentUser!.uid;
    var uuid = Uuid();

    try {
      await FirebaseFirestore.instance.collection('users').add({
        'uid': uid,
        'name': _nameController.text,
        'nickName': _nickNameController.text,
        'city': _cityController.text,
        'birthDate': _dateController.text,
        'profileImage': _base64Image,
        'profileId': uuid.v4(),
        "userPoint": null,
        'timestamp': FieldValue.serverTimestamp(),
        'dateTime': DateTime.now().millisecondsSinceEpoch,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bilgiler başarıyla yüklendi.")),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      }
    } catch (e) {
      print("FireStore hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bilgiler yüklenirken hata oluştu.")),
      );
    }
  }

  void _showFullImage(File imageFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: CircleAvatar(
                backgroundImage: FileImage(_image!),
                radius: 258,
              )),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    double height = MediaQuery.sizeOf(context).height;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0XFFF2F2F2),
        title: const Text(
          'Kullanıcı Bilgileri',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(
            left: width / 14, right: width / 14, top: height / 25),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: height / 40),
              _image != null
                  ? GestureDetector(
                      onTap: _pickImage,
                      onLongPress: () {
                        _showFullImage(_image!);
                      },
                      child: CircleAvatar(
                        radius: 85,
                        backgroundImage: FileImage(_image!),
                      ),
                    )
                  : CircleAvatar(
                      radius: 85,
                      backgroundImage:
                          _image != null ? FileImage(_image!) : null,
                      child: IconButton(
                        icon: const Icon(Icons.add_a_photo),
                        onPressed: _pickImage,
                      ),
                    ),
              SizedBox(height: height / 25),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                    vertical: height / 74.16, horizontal: width / 34.25),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(25.0),
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
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(right: width / 34.25),
                          child: const Icon(Icons.person),
                        ),
                        hintText: "İsim - Soyisim",
                        hintStyle: TextStyle(
                            color: _nameController.text.isEmpty
                                ? const Color.fromARGB(220, 168, 163, 161)
                                : const Color(0xFF282625)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: height / 45),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                    vertical: height / 74.16, horizontal: width / 34.25),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(25.0),
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
                    TextField(
                      controller: _nickNameController,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(right: width / 34.25),
                          child: const Icon(Icons.person_pin),
                        ),
                        hintText: "Kullanıcı Adı",
                        hintStyle: TextStyle(
                            color: _nameController.text.isEmpty
                                ? const Color.fromARGB(220, 168, 163, 161)
                                : const Color(0xFF282625)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: height / 45),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                    vertical: height / 74.16, horizontal: width / 34.25),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(25.0),
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
                    TextField(
                      controller: _cityController,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(right: width / 34.25),
                          child: const Icon(Icons.location_city),
                        ),
                        hintText: "Şehir",
                        hintStyle: TextStyle(
                            color: _nameController.text.isEmpty
                                ? const Color.fromARGB(220, 168, 163, 161)
                                : const Color(0xFF282625)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: height / 45),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                    vertical: height / 74.16, horizontal: width / 34.25),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(25.0),
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
                    TextField(
                      controller: _dateController,
                      onTap: () {
                        _selectDate(context);
                      },
                      readOnly: true,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(right: width / 34.25),
                          child: const Icon(Icons.person),
                        ),
                        hintText: "Doğum Tarihi",
                        hintStyle: TextStyle(
                            color: _nameController.text.isEmpty
                                ? const Color.fromARGB(220, 168, 163, 161)
                                : const Color(0xFF282625)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: height / 45),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: height / 44, horizontal: width / 55),
                  child: ElevatedButton(
                    onPressed: () {
                      _saveToFirestore();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8256DF),
                      padding: EdgeInsets.symmetric(
                          vertical: height / 56.33, horizontal: width / 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: Text(
                      'Kaydet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: height / 50,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
