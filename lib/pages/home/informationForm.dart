import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:students_follow_app/pages/home/home.dart';
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
      // Resmi base64'e dönüştür
      _base64Image = await _compressAndConvertToBase64(_image!);
    }
  }

  // Resmi sıkıştırıp base64 formatına dönüştürme fonksiyonu
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

  // Tarih seçici
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _dateController.text =
            "${selectedDate?.day}/${selectedDate?.month}/${selectedDate?.year}";
      });
    }
  }

  // Firestore'a kullanıcı bilgilerini yükleme fonksiyonu
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
                Navigator.of(context).pop(); // Resme tıklayınca dialogu kapatır
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kullanıcı Bilgileri',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 30, right: 30, top: 75),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _image != null
                  ? GestureDetector(
                      onTap: _pickImage,
                      onLongPress: () {
                        _showFullImage(
                            _image!); // Resme tıklayınca tam ekran açılır
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: FileImage(_image!),
                      ),
                    )
                  : CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          const AssetImage("assets/icons/unknow.svg"),
                      child: IconButton(
                        icon: const Icon(Icons.add_a_photo),
                        onPressed: _pickImage,
                      ),
                    ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "Ad",
                    prefixIcon: const Icon(Icons.person),
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
                  controller: _nickNameController,
                  decoration: InputDecoration(
                    hintText: "Kullanıcı Adı",
                    prefixIcon: const Icon(Icons.person_outline),
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
                  controller: _cityController,
                  decoration: InputDecoration(
                    hintText: "Şehir",
                    prefixIcon: const Icon(Icons.location_city),
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
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: "Doğum Tarihi",
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                  ),
                  onTap: () {
                    _selectDate(context);
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _saveToFirestore(); // Kaydetme işlemi
                },
                child: const Text("Kaydet"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
