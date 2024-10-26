import 'package:Tudora/pages/Leaderboard/leaderboard-all.dart';
import 'package:Tudora/pages/Leaderboard/leaderboard-friends.dart';
import 'package:flutter/material.dart';

class Leaderboard extends StatefulWidget {
  const Leaderboard({super.key});

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.sizeOf(context).height;
    return DefaultTabController(
      initialIndex: 1,
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF7A4FBD),
        appBar: AppBar(
          backgroundColor: const Color(0xFF7A4FBD),
          toolbarHeight: height / 80,
          bottom: const TabBar(
            indicatorColor: Colors.purple,
            labelColor: Colors.white,
            unselectedLabelColor: Color.fromARGB(255, 218, 218, 218),
            tabs: [
              Tab(
                  text: "Takip Ettiklerim",
                  icon: Icon(
                    Icons.person_pin,
                    color: Color.fromARGB(255, 255, 255, 255),
                  )),
              Tab(
                  text: "Herkes",
                  icon: Icon(
                    Icons.people_alt_sharp,
                    color: Color.fromARGB(255, 255, 255, 255),
                  )),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            LeaderBoardFriends(),
            LeaderboardPage(),
          ],
        ),
      ),
    );
  }
}
