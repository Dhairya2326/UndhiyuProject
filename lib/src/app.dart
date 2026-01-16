import 'package:flutter/material.dart';
import 'package:undhiyuapp/src/screens/home_screen.dart';
import 'package:undhiyuapp/src/constants/app_colors.dart';

class UndhiyuApp extends StatelessWidget {
  const UndhiyuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Undhiyu Billing',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
