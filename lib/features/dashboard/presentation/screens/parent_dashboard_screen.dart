import 'package:flutter/material.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم ولي الأمر'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'أهلاً بك! يمكنك هنا متابعة تقدم طفلك.',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
