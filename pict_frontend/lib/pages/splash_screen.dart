import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:pict_frontend/intro_screen.dart';
import 'package:pict_frontend/pages/Auth/signin_screen.dart';
import 'package:pict_frontend/pages/Organizer/organizer_dashboard.dart';
import 'package:pict_frontend/pages/Recycler/recycler_home_screen.dart';
import 'package:pict_frontend/pages/User/user_dashboard.dart';
import 'package:pict_frontend/utils/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    validateUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      margin: const EdgeInsets.only(top: 10),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/logo.png",
              height: 300,
            ),
            const SizedBox(
              height: 25,
            ),
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .5,
                  ),
                ),
                children: [
                  TextSpan(
                      text: 'Vasun',
                      style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)),
                  const TextSpan(
                    text: 'Dhara',
                    style: TextStyle(color: TColors.primaryGreen),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    ));
  }

  validateUser() {
    Timer(const Duration(milliseconds: 3500), () async {
      // ! If the user close the app, and then try to open it again, then he will be prompted to login again.

      var result = await SharedPreferences.getInstance();
      bool? data = result.getBool("isloggedIn");
      String? role = result.getString("role");
      bool? isVisited = result.getBool("isVisited");

      if (isVisited != null && isVisited == true) {
        if (data != null && data == true) {
          if (role == "user") {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) {
              return const UserDashboard();
            }));
          } else if (role == "organizer") {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) {
              return const OrganizerDashboard();
            }));
          } else if (role == "recycler") {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) {
              return const RecyclerHomePage();
            }));
          }
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) {
            return const SignInPage();
          }));
        }
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) {
          return const IntroScreen();
        }));
      }
    });
  }
}
