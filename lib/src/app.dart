import 'package:flutter/material.dart';
import 'package:undhiyuapp/src/screens/home_screen.dart';
import 'package:undhiyuapp/src/constants/app_colors.dart';
import 'package:undhiyuapp/src/themes/app_theme.dart';

class UndhiyuApp extends StatelessWidget {
  const UndhiyuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Undhiyu Billing',
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
