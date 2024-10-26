import 'package:Tudora/components/loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:Tudora/notification/firebase_api.dart';
import 'package:Tudora/pages/auth/login_register_page.dart';
import 'package:Tudora/pages/home/informationForm.dart';
import 'package:Tudora/pages/home/menu-home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Tudora/services/auth.dart';
import 'firebase_options.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseApi().initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool checkNick = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkUserStatus();
  }

  void checkUserStatus() {
    FirebaseAuth.instance.authStateChanges().listen((User? currentUser) {
      setState(() {
        user = currentUser;
        if (user != null) {
          checkNickName();
        } else {
          isLoading = false;
        }
      });
    });
  }

  Future<void> checkNickName() async {
    try {
      var users = await _firestore
          .collection("users")
          .where("uid", isEqualTo: Auth().currentUser!.uid)
          .limit(1)
          .get();

      if (users.docs.isNotEmpty) {
        var userDoc = users.docs.first;
        setState(() {
          checkNick = userDoc["nickName"].toString().isNotEmpty;
        });
      }
    } catch (e) {
      print("Kullanıcı adı kontrolü sırasında hata: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LoadingScreen(),
      );
    }

    return MaterialApp(
      title: 'Tudora',
      navigatorKey: navigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('tr', ''),
      ],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: user == null
          ? const LoginRegisterPage()
          : (checkNick ? const MenuHome() : const InformationForm()),
    );
  }
}
