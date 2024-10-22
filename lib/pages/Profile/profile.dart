import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
  String? profileImage;
  String? errorMessage;
  String userNickName = "";
  String? userId;

  String? authUserId;
  String? authUserNickName;

  int numberOfFollowers = 0;
  int numberOfFollowed = 0;

  bool isFollewed = false;

  int totalPoints = 0;
  int points = 0;
  StreamSubscription? followersSubscription;

  @override
  void initState() {
    super.initState();
    fetchUserFollowers();
    fetchUserInfo();
    fetchUserInfoByUserId();
    listenToUserFollowers();
  }

  void dispose() {
    // Abonelikleri iptal et
    followersSubscription?.cancel();
    super.dispose();
  }

  void listenToUserFollowers() {
    // Takip edilen kullanıcıların verisini dinle
    followersSubscription = FirebaseFirestore.instance
        .collection('followers')
        .doc(widget
            .userID) // Hangi kullanıcının takipçilerini dinleyecekseniz onu belirtin
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final takipEdenler = data['takipEdenler'] ?? [];
        final takipEdilen = data['takipEdilen'] ?? [];

        // Anlık olarak gelen takipçi ve takip edilen sayılarını güncelle
        setState(() {
          numberOfFollowers = takipEdenler.length;
          numberOfFollowed = takipEdilen.length;

          // Auth ile aynı ID'ye sahip biri varsa takip durumunu güncelle
          isFollewed = takipEdenler
              .any((item) => item['userId'] == Auth().currentUser!.uid);
        });
      }
    });
  }

  Future<void> fetchUserFollowers() async {
    try {
      final userFollowers = await Auth().fetchFollowersByUid(widget.userID);
      if (userFollowers.isNotEmpty) {
        final takipEdenler = userFollowers[0]['takipEdenler'] ?? [];
        final takipEdilen = userFollowers[0]['takipEdilen'] ?? [];

        for (var item in takipEdenler) {
          if (item['userId'] == Auth().currentUser!.uid) {
            setState(() {
              isFollewed = true;
            });
            break;
          }
        }
        final countTakipEdenler = takipEdenler.length;
        final counttakipEdilen = takipEdilen.length;
        setState(() {
          numberOfFollowers = countTakipEdenler;
          numberOfFollowed = counttakipEdilen;
        });
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
        final takipEdenler = userInfos[0]['userPoint'] ?? [];

        // Tüm userPoint değerlerini toplamak için bir değişken oluştur
        dynamic totalPoints = 0;

        // Her bir öğeyi kontrol et ve userPoint değerini topla
        for (var point in takipEdenler) {
          totalPoints += point['userPoint']; // Burada num'u int'e çeviriyoruz
        }

        setState(() {
          profileImage = userInfos[0]['profileImage'];
          userName = userInfos[0]['name'];
          userNickName = userInfos[0]["nickName"];
          userId = userInfos[0]["uid"];
          points = totalPoints; // Toplanan puanı burada ayarla
        });
      } else {
        setState(() {
          profileImage = null;
          userNickName = "";
          userName = "";
          userId = "";
          points = 0; // Eğer kullanıcı bulunamazsa puanı sıfırla
        });
      }
    } catch (e) {
      print("Error fetching user info: $e");
      // Hata durumunda da puanı sıfırlayabilirsin
      setState(() {
        points = 0; // Hata durumunda puanı sıfırla
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

  Future<void> unFollowUser() async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('followers')
          .doc(authUserId) // Geçerli kullanıcının ID'sine göre belgeyi bul
          .get();

      List<dynamic> takipEdilenListesi = docSnapshot['takipEdilen'] ?? [];

      // userId'yi içeren öğeyi takip edilen listesinden çıkar
      takipEdilenListesi.removeWhere((item) => item['userId'] == userId);

      // Güncellenmiş takip edilen listesini Firestore'da güncelle
      await FirebaseFirestore.instance
          .collection('followers')
          .doc(authUserId)
          .update({
        'takipEdilen': takipEdilenListesi,
      });

      DocumentSnapshot docSnapshot2 = await FirebaseFirestore.instance
          .collection('followers')
          .doc(userId) // Geçerli kullanıcının ID'sine göre belgeyi bul
          .get();

      List<dynamic> takipEdenlerListesi = docSnapshot2['takipEdenler'] ?? [];

      // userId'yi içeren öğeyi takip edilen listesinden çıkar
      takipEdenlerListesi.removeWhere((item) => item['userId'] == authUserId);

      // Güncellenmiş takip edilen listesini Firestore'da güncelle
      await FirebaseFirestore.instance
          .collection('followers')
          .doc(userId)
          .update({
        'takipEdenler': takipEdenlerListesi,
      });
      print("Takipten Cikma basarili user id $authUserId");
    } catch (e) {
      print("Takipten Cıkma Basarisiz $e");
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: (widget.userID == Auth().currentUser!.uid)
            ? const Text("Profil Bilgilerin")
            : const Text("Profil Bilgileri"),
      ),
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
                            if (widget.userID != Auth().currentUser!.uid)
                              FloatingActionButton.extended(
                                onPressed: () {
                                  isFollewed == true
                                      ? unFollowUser()
                                      : followUser(widget.userID!, userName);
                                },
                                heroTag: 'follow',
                                elevation: 0,
                                label: isFollewed
                                    ? const Text("Takibi Bırak")
                                    : const Text("Takip Et"),
                                icon: isFollewed
                                    ? const Icon(Icons.person_remove_alt_1)
                                    : const Icon(Icons.person_add_alt_1),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ProfileInfoRow(
                            userPoint: points,
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
        ProfileInfoItem("Toplam Puan", userPoint),
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
