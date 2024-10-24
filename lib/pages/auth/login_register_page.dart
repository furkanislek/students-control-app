import 'package:flutter/material.dart';
import 'package:students_follow_app/pages/auth/login.dart';
import 'package:students_follow_app/pages/auth/register.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return isLogin ? const Login() : const Register();
  }
}
