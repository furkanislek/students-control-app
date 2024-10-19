import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:students_follow_app/components/menu/menu.dart';
import 'package:students_follow_app/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Profile extends StatefulWidget {
  final String? userID;

  const Profile({Key? key, required this.userID}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String userName = "";
  int userPoint = 9560;
  String? profileImage;
  String? errorMessage;
  String userNickName = "";
  String? userId;

  String? authUserId;
  String? authUserNickName;

  int numberOfFollowers = 0;
  int numberOfFollowed = 0;

  @override
  void initState() {
    super.initState();
    fetchUserFollowers();
    fetchUserInfo();
    fetchUserInfoByUserId();
  }

  Future<void> fetchUserFollowers() async {
    try {
      final userFollowers = await Auth().fetchFollowersByUid(widget.userID);
      print(userFollowers);
      print(widget.userID);
      print(
          "************************************************************************");
      print(
          "************************************************************************");
      if (userFollowers.isNotEmpty) {
        final takipEdenler = userFollowers[0]['takipEdenler'];
        final takipEdilen = userFollowers[0]['takipEdilen'] ?? [];
        final countTakipEdenler = takipEdenler.length;
        final counttakipEdilen = takipEdilen.length;
        setState(() {
          numberOfFollowers = countTakipEdenler;
          numberOfFollowed = counttakipEdilen;
        });
        print(userFollowers);
        print("-----------------------------------------------------------");
        print("-----------------------------------------------------------");
      } else {
        setState(() {
          numberOfFollowers = 0;
          numberOfFollowed = 0;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  Future<void> fetchUserInfo() async {
    try {
      final userInfos = await Auth().fetchUserInfo();
      if (userInfos != null && userInfos.isNotEmpty) {
        setState(() {
          authUserId = userInfos[0]['uid'];
          authUserNickName = userInfos[0]['nickName'];
        });
      } else {
        setState(() {
          authUserId = "";
          authUserNickName = "";
        });
      }
      print("user Info  2 $authUserId  $authUserNickName");
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  Future<void> fetchUserInfoByUserId() async {
    try {
      final userInfos = await Auth().fetchUserInfoByUid(widget.userID);
      if (userInfos != null && userInfos.isNotEmpty) {
        setState(() {
          profileImage = userInfos[0]['profileImage'];
          userName = userInfos[0]['name'];
          userNickName = userInfos[0]["nickName"];
          userPoint = userInfos[0]['points'] ?? userPoint;
          userId = userInfos[0]["uid"];
        });
      } else {
        setState(() {
          profileImage = null;
          userNickName = "";
          userName = "";
          userId = "";
        });
      }

      print("user Nick $userId");
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  Uint8List? decodeBase64Image(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  Future<void> followUser(
      String followedUserId, String followedUserName) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception("User not logged in.");
      }

      final followersCollection =
          FirebaseFirestore.instance.collection('followers');

      await followersCollection.doc(authUserId).set({
        "userId": authUserId, //test
        "nickName": authUserNickName, //test
        "timeStamp": Timestamp.now(),
        'takipEdilen': FieldValue.arrayUnion([
          {
            'userId': userId,
            'nickName': userNickName,
            'dateTime': DateTime.now().millisecondsSinceEpoch,
          },
        ])
      }, SetOptions(merge: true));

      await followersCollection.doc(userId).set({
        "userId": userId,
        "nickName": userNickName,
        'takipEdenler': FieldValue.arrayUnion([
          {
            'userId': authUserId,
            'nickName': authUserNickName,
            'dateTime': DateTime.now().millisecondsSinceEpoch,
          }
        ])
      }, SetOptions(merge: true));

      print("Takip işlemi başarılı.");
    } catch (e) {
      print("Takip işlemi başarısız: $e");
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profilin"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      drawer: const Menu(),
      body: RefreshIndicator(
        onRefresh: fetchUserInfo,
        child: Stack(
          children: [
            SvgPicture.asset(
              "assets/icons/blog.svg", // Background SVG
              fit: BoxFit.cover,
              width: 250,
              height: double.infinity,
            ),
            Column(
              children: [
                Expanded(
                    flex: 2, child: _TopPortion(profileImage: profileImage)),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          userName.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FloatingActionButton.extended(
                              onPressed: () {
                                followUser(widget.userID!, userName);
                              },
                              heroTag: 'follow',
                              elevation: 0,
                              label: const Text("Follow"),
                              icon: const Icon(Icons.person_add_alt_1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ProfileInfoRow(
                            userPoint: userPoint,
                            numberOfFollowers: numberOfFollowers,
                            numberOfFollowed: numberOfFollowed)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final int userPoint;
  final int numberOfFollowers;
  final int numberOfFollowed;

  const _ProfileInfoRow(
      {required this.userPoint,
      required this.numberOfFollowers,
      required this.numberOfFollowed});

  List<ProfileInfoItem> get items => [
        ProfileInfoItem("Soru Sayısı", userPoint),
        ProfileInfoItem("Takip Edilenler", numberOfFollowed),
        ProfileInfoItem("Takipçiler", numberOfFollowers),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      constraints: const BoxConstraints(maxWidth: 350),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items
            .map((item) => Expanded(
                    child: Row(
                  children: [
                    if (items.indexOf(item) > 0) const VerticalDivider(),
                    Expanded(child: _singleItem(context, item)),
                  ],
                )))
            .toList(),
      ),
    );
  }

  Widget _singleItem(BuildContext context, ProfileInfoItem item) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              item.value.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          Text(
            item.title,
          )
        ],
      );
}

class ProfileInfoItem {
  final String title;
  final int value;
  const ProfileInfoItem(this.title, this.value);
}

class _TopPortion extends StatelessWidget {
  final String? profileImage; // Accept profileImage as a parameter

  const _TopPortion({Key? key, this.profileImage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    backgroundImage: profileImage != null
                        ? MemoryImage(decodeBase64Image(profileImage!)!)
                        : null,
                    radius: 90,
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Uint8List? decodeBase64Image(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null; // Return null in case of error
    }
  }
}
