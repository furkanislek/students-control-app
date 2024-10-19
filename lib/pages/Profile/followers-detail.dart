import 'package:flutter/material.dart';
import 'package:students_follow_app/services/auth.dart';

class FollowersPage extends StatefulWidget {
  final String userID;

  const FollowersPage({Key? key, required this.userID}) : super(key: key);

  @override
  _FollowersPageState createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  List<dynamic> followersList = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchFollowers();
  }

  // Firestore'dan takipçi listesini çeken fonksiyon
  Future<void> fetchFollowers() async {
    try {
      setState(() {
        isLoading = true;
      });
      final userFollowers = await Auth().fetchFollowersByUid(widget.userID);
      if (userFollowers.isNotEmpty) {
        setState(() {
          followersList = userFollowers[0]['takipEdenler'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          followersList = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Takipçiler"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : followersList.isEmpty
              ? const Center(child: Text("Hiç takipçi bulunmuyor"))
              : ListView.builder(
                  itemCount: followersList.length,
                  itemBuilder: (context, index) {
                    var follower = followersList[index];
                    return ListTile(
                      title: Text(follower['nickName']),
                      subtitle: Text(_formatDateTime(follower['dateTime'])),
                    );
                  },
                ),
    );
  }

  // Tarih ve zaman formatlama fonksiyonu
  String _formatDateTime(int dateTimeMillis) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(dateTimeMillis);
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour}:${dateTime.minute}";
  }
}
