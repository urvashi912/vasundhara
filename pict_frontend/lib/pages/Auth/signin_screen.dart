import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:pict_frontend/pages/Auth/signup_screen.dart';
import 'package:pict_frontend/pages/Organizer/organizer_dashboard.dart';
import 'package:pict_frontend/pages/Recycler/recycler_home_screen.dart';
import 'package:pict_frontend/pages/User/user_dashboard.dart';
import 'package:pict_frontend/services/auth_service.dart';
import 'package:pict_frontend/utils/constants/app_colors.dart';
import 'package:pict_frontend/utils/constants/app_constants.dart';
import 'package:pict_frontend/utils/session/SharedPreference.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  var logger = Logger();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController =
  TextEditingController(text: "");
  final TextEditingController _passwordController =
  TextEditingController(text: "");

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    AppConstants.loginIcon,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20.0),
                const Text(
                  "Sign In",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 35,
                    color: TColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.grey.shade300),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? TColors.black
                        : TColors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 0, 5),
                          child: Text(
                            "Your Email Address:",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter Your Email Address";
                            } else if (!value.contains('@')) {
                              return "Enter a valid Email Address";
                            }
                            return null;
                          },
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 0, 5),
                          child: Text(
                            "Your Password:",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter Your Password";
                            }
                            return null;
                          },
                          controller: _passwordController,
                          obscureText: true,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                Map<String, dynamic> response =
                                await AuthServices.signIn(
                                  _emailController.text,
                                  _passwordController.text,
                                );

                                logger.i('Response from server: $response');

                                if (response["result"] != "Invalid Credentials" &&
                                    response["result"]["message"] == "ok") {
                                  var account = response["result"]["data"];
                                  logger.i('Account data: $account');

                                  if (account != null) {
                                    String res = await Utils.setSession(account);

                                    if (res == "ok") {
                                      if (account["role"] == "user") {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                            const UserDashboard(),
                                          ),
                                        );
                                      } else if (account["role"] ==
                                          "recycler") {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                            const RecyclerHomePage(),
                                          ),
                                        );
                                      } else if (account["role"] ==
                                          "organizer") {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                            const OrganizerDashboard(),
                                          ),
                                        );
                                      } else {
                                        Fluttertoast.showToast(
                                          msg: "Unknown role",
                                          backgroundColor: Colors.orange,
                                        );
                                      }
                                    } else {
                                      Fluttertoast.showToast(
                                        msg: "Failed to save session",
                                        backgroundColor: Colors.red,
                                      );
                                    }
                                  } else {
                                    Fluttertoast.showToast(
                                      msg: "Invalid account data",
                                      backgroundColor: Colors.red,
                                    );
                                  }
                                } else if (response["result"] ==
                                    "Invalid Credentials") {
                                  Fluttertoast.showToast(
                                    msg: "Invalid Credentials",
                                    backgroundColor: Colors.red,
                                  );
                                } else {
                                  Fluttertoast.showToast(
                                    msg: "Internal Server Error",
                                    backgroundColor: Colors.red,
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TColors.primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                "Sign In",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Not have an account?",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
