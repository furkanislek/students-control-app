import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:students_follow_app/components/menu/menu.dart';
import 'package:students_follow_app/services/auth.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String userName = "";
  int userPoint = 9560;
  String? profileImage;
  String? errorMessage;
  String? userId;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    try {
      final userInfos = await Auth().fetchUserInfo();
      if (userInfos != null && userInfos.isNotEmpty) {
        setState(() {
          profileImage = userInfos[0]['profileImage'];
          userName = userInfos[0]['name'];
          userId = userInfos[0]['uid'];
          userPoint = userInfos[0]['points'] ?? userPoint;
        });
      } else {
        setState(() {
          profileImage = null;
          userName = "";
        });
      }
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
      return null; // Return null in case of error
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profilin"),
      ),
      drawer: const Menu(),
      body: RefreshIndicator(
        onRefresh: fetchUserInfo,
        child: Column(
          children: [
            Expanded(flex: 2, child: _TopPortion(profileImage: profileImage)),
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
                            // Handle follow action
                          },
                          heroTag: 'follow',
                          elevation: 0,
                          label: const Text("Follow"),
                          icon: const Icon(Icons.person_add_alt_1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ProfileInfoRow(userPoint: userPoint)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final int userPoint;
  const _ProfileInfoRow({Key? key, required this.userPoint}) : super(key: key);

  List<ProfileInfoItem> get items => [
        ProfileInfoItem("Posts", userPoint),
        const ProfileInfoItem("Followers", 120),
        const ProfileInfoItem("Following", 200),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      constraints: const BoxConstraints(maxWidth: 400),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                        ? MemoryImage(decodeBase64Image(
                            profileImage!)!) // Profil resmi varsa
                        : const AssetImage(
                            "assets/icons/unknow.svg"), // Varsayılan resim
                    radius: 90, // Çemberin yarıçapı
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
