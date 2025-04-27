import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final String initialRole;

  const HomeScreen({super.key, required this.initialRole});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('홈')),
      body: Center(child: Text('${widget.initialRole} 역할의 홈 화면')),
    );
  }
}
