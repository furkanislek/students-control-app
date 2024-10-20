import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gradient_app_bar/flutter_gradient_app_bar.dart';
import 'package:students_follow_app/pages/Profile/profile.dart';

class User {
  String name;
  String nickName;
  String profileImage;
  dynamic totalPoints;
  String userId;

  User({
    required this.name,
    required this.nickName,
    required this.profileImage,
    required this.totalPoints,
    required this.userId,
  });

  @override
  String toString() {
    return 'User{name: $name, nickName: $nickName, totalPoints: $totalPoints ,profileImage: $profileImage, userId: $userId}';
  }
}

Uint8List? decodeBase64Image(String base64String) {
  try {
    return base64Decode(base64String);
  } catch (e) {
    return null; // Return null in case of error
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<User> userList = [];
  List<User> topUsers = [];
  List<User> remainingUsers = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    List<User> users = [];

    // Firestore'dan 'users' koleksiyonunu çekiyoruz.
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    // Her bir dokümanı gezip gerekli verileri işliyoruz.
    querySnapshot.docs.forEach((doc) {
      // `userPoints` altındaki `userPoint` değerlerini toplamak için
      List<dynamic> userPoints = doc['userPoint'] ?? [];
      dynamic totalPoints = userPoints.fold(0.0, (dynamic sum, dynamic point) {
        return sum + (point['userPoint'] ?? 0);
      });

      users.add(User(
          name: doc['name'],
          nickName: doc['nickName'],
          profileImage: doc['profileImage'],
          totalPoints: totalPoints,
          userId: doc["uid"] ?? ""));
    });

    // Puanlara göre sıralıyoruz (yüksekten düşüğe)
    users.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    // İlk 3 kullanıcıyı ayırıyoruz
    setState(() {
      topUsers = users.take(3).toList(); // İlk 3 kullanıcı
      remainingUsers = users.skip(3).toList(); // Geri kalanlar
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 255, 238, 0),
            Color.fromARGB(255, 219, 161, 0),
          ],
        ),
        title:const Text(
          "Sıralama",
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 24)),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black, // Set the color of the back button to black
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            child: Column(
              children: [
                Image.asset(
                  "assets/leaderboard/leaderboard.png",
                  fit: BoxFit.cover,
                ),
                SizedBox(
                  height: 25,
                  child: Image.asset(
                    "assets/leaderboard/line.png",
                    fit: BoxFit.fill,
                  ),
                )
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height / 2.5,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: remainingUsers.length,
                itemBuilder: (context, index) {
                  final user = remainingUsers[index];
                  return Padding(
                    padding:
                        const EdgeInsets.only(right: 20, left: 20, bottom: 15),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    Profile(userID: user.userId)));
                      },
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      Profile(userID: user.userId)));
                        },
                        child: Row(
                          children: [
                            Text(
                              (index + 4).toString(), // 4. sıradan başlat
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Container(
                              padding:
                                  const EdgeInsets.all(2), // Kenarlık için alan
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(
                                    255, 82, 73, 0), // Kenarlık rengi
                                shape: BoxShape.circle, // Yuvarlak kenarlık
                              ),
                              child: CircleAvatar(
                                backgroundImage: MemoryImage(
                                    decodeBase64Image(user.profileImage)!),
                                radius: 30,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Text(
                              user.nickName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              height: 25,
                              width: 70,
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 5),
                                  const RotatedBox(
                                    quarterTurns: 0,
                                    child: Icon(
                                      Icons.leaderboard,
                                      color: Color.fromARGB(255, 255, 187, 0),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    user.totalPoints.toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Positioned(
            top: 20,
            right: 150,
            child: Text(
              "Sıralamalar",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 1. sıralama
          if (topUsers.isNotEmpty)
            Positioned(
              top: 125,
              right: 165,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              Profile(userID: topUsers[0].userId)));
                },
                child: rank(
                  radius: 45.0,
                  height: 10,
                  image: topUsers[0].profileImage,
                  name: topUsers[0].nickName,
                  point: topUsers[0].totalPoints.toString(),
                ),
              ),
            ),
          // 2. sıralama
          if (topUsers.length > 1)
            Positioned(
              top: 190,
              left: 50,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              Profile(userID: topUsers[1].userId)));
                },
                child: rank(
                  radius: 30.0,
                  height: 10,
                  image: topUsers[1].profileImage,
                  name: topUsers[1].nickName,
                  point: topUsers[1].totalPoints.toString(),
                ),
              ),
            ),
          // 3. sıralama
          if (topUsers.length > 2)
            Positioned(
              top: 220,
              right: 25,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              Profile(userID: topUsers[2].userId)));
                },
                child: rank(
                  radius: 30.0,
                  height: 10,
                  image: topUsers[2].profileImage,
                  name: topUsers[2].nickName,
                  point: topUsers[2].totalPoints.toString(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Column rank({
    required double radius,
    required double height,
    required String image,
    required String name,
    required String point,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 82, 73, 0),
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(decodeBase64Image(image)!),
          ),
        ),
        SizedBox(height: height),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: height),
        Container(
          height: 25,
          width: 70,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            children: [
              const SizedBox(width: 5),
              const Icon(
                Icons.leaderboard,
                color: Color.fromARGB(255, 255, 187, 0),
              ),
              const SizedBox(width: 5),
              Text(
                point,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
