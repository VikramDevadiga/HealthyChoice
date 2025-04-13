import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/logo_screen.dart';  // Import the LogoScreen

void main() {
  runApp(NutritionAssistantApp());
}

class NutritionAssistantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrition Assistant',
      theme: ThemeData(
        primaryColor: Color(0xFF6D30EA),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        fontFamily: 'Inter',
      ),
      home: LogoScreen(),   // Use LogoScreen as the initial screen
      debugShowCheckedModeBanner: false,
    );
  }
}
