import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Tudora/pages/Profile/profile.dart';

import '../../components/loading.dart';

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
    return 'User{name: $name, nickName: $nickName, totalPoints: $totalPoints, profileImage: $profileImage, userId: $userId}';
  }
}

class LeaderboardPage extends StatefulWidget {
  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  Uint8List? decodeBase64Image(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  List<User> userList = [];
  List<User> topUsers = [];
  List<User> remainingUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    List<User> users = [];
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    querySnapshot.docs.forEach((doc) {
      List<dynamic> userPoints = doc['userPoint'] ?? [];
      dynamic totalPoints = userPoints.fold(0.0, (dynamic sum, dynamic point) {
        return sum + (point['userPoint'] ?? 0);
      });

      users.add(User(
        name: doc['name'],
        nickName: doc['nickName'],
        profileImage: doc['profileImage'],
        totalPoints: totalPoints,
        userId: doc["uid"] ?? "",
      ));
    });

    users.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    setState(() {
      topUsers = users.take(3).toList();
      remainingUsers = users.skip(3).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    double height = MediaQuery.sizeOf(context).height;
    if (isLoading) {
      return const LoadingScreen();
    }

    return topUsers.isNotEmpty
        ? Scaffold(
            backgroundColor: const Color(0xFF7A4FBD),
            body: Container(
              color: const Color(0xFFF2F2F2),
              height: height,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7A4FBD),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(50),
                        bottomRight: Radius.circular(50),
                      ),
                    ),
                    height: height * 0.4,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: height * 0.07),
                          child: Column(
                            children: [
                              Text(
                                topUsers[1].nickName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: height / 59.33,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: height / 89),
                              _buildTopUserContainer(
                                  context, width * 1.1, height, topUsers[1],
                                  color: const Color(0xFF87D89B),
                                  icons: Icons.looks_two),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: height / 74.17),
                          child: Column(
                            children: [
                              Text(
                                topUsers[0].nickName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: height / 59.33,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              _buildTopUserContainer(context, width * 1.1,
                                  height * 1.2, topUsers[0],
                                  color: const Color(0xFF2C9AE9),
                                  icons: Icons.looks_one),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: height * 0.1),
                          child: Column(
                            children: [
                              Text(
                                topUsers[2].nickName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: height / 59.33,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              _buildTopUserContainer(
                                context,
                                width * 1.1,
                                height,
                                topUsers[2],
                                color: const Color(0xFFD8B1EE),
                                icons: Icons.looks_3,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: height / 44.5),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: remainingUsers.length,
                      itemBuilder: (context, index) {
                        final user = remainingUsers[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color.fromARGB(255, 185, 185, 185)
                                          .withOpacity(0.2),
                                  spreadRadius: 10,
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            width: double.infinity,
                            height: height * 0.08,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  right: 20, left: 20, bottom: 5, top: 5),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          Profile(userID: user.userId),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      (index + 4).toString(),
                                      style: TextStyle(
                                        fontSize: height / 63.57,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: width / 27.4),
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Color.fromARGB(255, 82, 73, 0),
                                        shape: BoxShape.circle,
                                      ),
                                      child: CircleAvatar(
                                        backgroundImage: MemoryImage(
                                            decodeBase64Image(
                                                user.profileImage)!),
                                        radius: 30,
                                      ),
                                    ),
                                    SizedBox(width: width / 27.4),
                                    Text(
                                      user.nickName,
                                      style: TextStyle(
                                        fontSize: height / 59.33,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      height: height / 35.6,
                                      width: width / 5.87,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 5),
                                          const RotatedBox(
                                            quarterTurns: 0,
                                            child: Icon(
                                              Icons.leaderboard,
                                              color: Color.fromARGB(
                                                  255, 255, 187, 0),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            user.totalPoints.toString(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: height / 89,
                                              color: Colors.black,
                                            ),
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
                      },
                    ),
                  ),
                ],
              ),
            ),
          )
        : Scaffold();
  }

  Widget _buildTopUserContainer(
      BuildContext context, double width, double height, User user,
      {required Color color, required dynamic icons}) {
    return Container(
      width: width * 0.25,
      height: height * 0.25,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        color: color,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(100),
          bottomRight: Radius.circular(100),
          topLeft: Radius.circular(100),
          topRight: Radius.circular(100),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          CircleAvatar(
            radius: 38,
            backgroundImage: (user.profileImage.isNotEmpty)
                ? MemoryImage(decodeBase64Image(user.profileImage)!)
                : null,
          ),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            width: 90,
            child: Row(
              children: [
                Icon(icons),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 11.0, horizontal: 4),
                    child: Text(
                      '${user.totalPoints.toStringAsFixed(0)} Points',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
