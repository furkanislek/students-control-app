import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:students_follow_app/pages/auth/login_register_page.dart';
import 'package:students_follow_app/services/auth.dart';
import 'package:students_follow_app/pages/home/home.dart'; // Home sayfasını içe aktar

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

  bool isLogin = true;
  String? errorMessage;
  DateTime? selectedDate;

  Future<void> signOut() async {
    try {
      await Auth().signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginRegisterPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> addDetails({
    required String name,
    required String city,
    required String nickName,
    required DateTime date,
    required dynamic uid,
  }) async {
    if (Auth().currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection("users").add({
          'name': name,
          'nickName': nickName,
          'city': city,
          'date': date,
          'uid': uid,
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      } catch (e) {
        setState(() {
          errorMessage = 'Error saving details: ${e.toString()}';
        });
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.only(left: 30, right: 30, top: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 1),
            SvgPicture.asset("assets/icons/info.svg", height: 300),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SizedBox(
                width: double.infinity,
                child: TextFormField(
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "Furkan ISLEK",
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Icon(Icons.person),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: _nickNameController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  hintText: "sagoceza",
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.person_outline),
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
                controller: _cityController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.streetAddress,
                decoration: InputDecoration(
                  hintText: "Gaziantep",
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.location_city),
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
                controller: _dateController,
                textInputAction: TextInputAction.next,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: "Doğum Tarihi",
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.calendar_today),
                  ),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedDate != null) {
                    addDetails(
                      name: _nameController.text,
                      city: _cityController.text.trim(),
                      nickName: _nickNameController.text,
                      date: selectedDate!,
                      uid: Auth().currentUser?.uid,
                    );
                  } else {
                    setState(() {
                      errorMessage = "Lütfen doğum tarihini seçin.";
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 226, 211, 245),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                child: Text(
                  "Kaydet".toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 226, 211, 245),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                child: Text(
                  "Çıkış Yap".toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
