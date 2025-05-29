import 'package:flutter/material.dart';

class AppConstants {
  static const String port = "4000";
  static const String IP = "http://10.12.91.63:$port";

  static const String imgsrc= "https://upload.wikimedia.org/wikipedia/commons/4/44/Recycle001.svg";
  static Color bgColorAuth = const Color(0xfff7f6fb);
  static const String registerIcon = "assets/images/register.svg";
  static const String loginIcon = "assets/images/login.png";

  static const months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];

  static String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  static const apiKey = "AIzaSyAXfwSmYwayAQLU9yQuUlSB1V8Wq1BGJ4s";
}
