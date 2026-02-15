import 'package:expencetracker/login.dart';
import 'package:expencetracker/mainPage.dart';
import 'package:expencetracker/signup.dart';
import 'package:expencetracker/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'splashscreen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  Future<Widget> _getFirstPage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedEmail = prefs.getString('email');

    if (savedEmail != null && savedEmail.isNotEmpty) {
      return MainPage(currentIndex: 0, userEmail: savedEmail);
    } else {
      return const Splashscreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getFirstPage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading screen while checking SharedPreferences
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: snapshot.data!,
            routes: {
              MyRoutes.Login: (context) => const Login(),
              MyRoutes.Signup: (context) => const Signup(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == MyRoutes.MainPage) {
                final userEmail = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (context) =>
                      MainPage(currentIndex: 0, userEmail: userEmail),
                );
              }
              return null;
            },
          );
        } else {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: Text("Error loading app")),
            ),
          );
        }
      },
    );
  }
}
