import 'package:flutter/material.dart';

class MessagePage extends StatelessWidget {
  final String name;
  const MessagePage({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
    );
  }
}
