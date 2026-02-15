import 'dart:convert';

import 'package:expencetracker/impVar.dart';
import 'package:expencetracker/mainPage.dart';
import 'package:expencetracker/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // @override
  // void initState() {
  //   super.initState();
  //   checkLoginStatus();
  // }

  // Future<void> checkLoginStatus() async {
  //   final SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final String? savedEmail = prefs.getString('email');
  //   if (savedEmail != null && savedEmail.isNotEmpty) {
  //     Navigator.of(context).pushReplacement(
  //       MaterialPageRoute(
  //         builder: (context) =>
  //             MainPage(currentIndex: 0, userEmail: savedEmail),
  //       ),
  //     );
  //   }
  // }

  bool viewpass = true;
  String emailhint = 'Email';
  String passhint = 'Password';
  final _formkey = GlobalKey<FormState>();
  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();
  // String? emailError;
  bool isLoading = false;
  String errorMessage = '';
  // String? passError;
  String emailErrorMessage = '';
  String passErrorMessage = '';
  // bool userData = false;

  // String loginError = '';

  void passwordvisibility() {
    setState(() {
      viewpass = !viewpass;
    });
  }

  Future<void> saveLoginInfo(String EmailId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', EmailId);
  }

  Future<void> loginUser() async {
    setState(() {
      isLoading = true;
      errorMessage = ''; // Reset any previous error message
    });
    Future.delayed(Duration(seconds: 5), () {
      if (isLoading) {
        setState(() {
          errorMessage = 'Server is not responding..';
          isLoading = false; // Stop the loading indicator after 3 seconds
        });
      }
    });
    try {
      final object = {
        "email": email.text,
        "password": pass.text,
      };

      final response = await http.post(
        Uri.parse('${server}login/loginUser'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(object),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        if (responseBody['error'] == "User not found") {
          setState(() {
            emailErrorMessage = 'Email does not exist';
          });
        } else if (responseBody['error'] == "Incorrect password") {
          setState(() {
            passErrorMessage = 'Incorrect Password';
          });
        } else if (responseBody['msg'] == "success") {
          final String EmailId = email.text;
          print('User email id:' + EmailId);
          saveLoginInfo(EmailId);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  MainPage(currentIndex: 0, userEmail: email.text),
            ),
          );
        }
      } else {
        setState(() {
          errorMessage = 'Server is not responding..';
        });
        print("Error: ${response.statusCode} ${response.reasonPhrase}");
      }
    } catch (err) {
      print('Login error: $err');
      // print('Login error: $err');
      setState(() {
        errorMessage = 'Server is not responding..';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 50,
              ),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue, Colors.purple],
                ).createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                child: Text(
                  'Log In',
                  style: GoogleFonts.raleway(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors
                        .white, // Color must be set for ShaderMask to work
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                child: Form(
                  key: _formkey,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          controller: email,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide:
                                  BorderSide(color: Colors.grey, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            prefixIcon: Icon(Icons.email_outlined),
                            fillColor: Colors.grey[100],
                            filled: true,
                            // border: OutlineInputBorder(),
                            hintText: "Email",
                            labelText: emailhint,
                            labelStyle: TextStyle(
                              color: (emailhint == 'Email does not exist' ||
                                      emailhint == 'Invalid Email')
                                  ? Colors.red
                                  : const Color.fromARGB(
                                      255, 110, 110, 110), // default color
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            } else if (emailErrorMessage.isNotEmpty) {
                              return emailErrorMessage;
                            }
                            return null;
                          }),
                      SizedBox(
                        height: 30,
                      ),
                      TextFormField(
                          controller: pass,
                          obscureText: viewpass,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock),
                            fillColor: Colors.grey[100],
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide:
                                  BorderSide(color: Colors.grey, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            // suffixIcon: Icon(Icons.check),

                            hintText: "Password",
                            labelText: passhint,
                            labelStyle: TextStyle(
                              color: (passhint == 'Incorrect Password' ||
                                      passhint == 'Invalid Password')
                                  ? Colors.red
                                  : const Color.fromARGB(
                                      255, 110, 110, 110), // default color
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                viewpass
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () async {
                                passwordvisibility();
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            } else if (passErrorMessage.isNotEmpty) {
                              return passErrorMessage;
                            }
                            return null;
                          }),
                      SizedBox(
                        height: 40,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.blue, Colors.purple],
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            passErrorMessage = '';
                            emailErrorMessage = '';
                            if (_formkey.currentState!.validate()) {
                              setState(() {
                                emailErrorMessage = '';
                                passErrorMessage = '';
                              });
                              await loginUser();
                              _formkey.currentState!.validate();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                                horizontal: 130, vertical: 15),
                            textStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: isLoading
                              ? Container(
                                  width: 20.0, // Set your desired width
                                  height: 20.0, // Set your desired height
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  "Log in",
                                  style: GoogleFonts.raleway(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      if (errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$errorMessage',
                                style: TextStyle(color: Colors.red),
                              ),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pushNamedAndRemoveUntil(context,
                                        MyRoutes.Login, (route) => false);
                                  },
                                  child: Text(
                                    'Try again',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ))
                            ],
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have any account?",
                            style: GoogleFonts.raleway(),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                  context, MyRoutes.Signup, (route) => false);
                            },
                            child: Text(
                              'SignUp',
                              style: GoogleFonts.raleway(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ), //column
                ),
              ),
            ],
          )),
        ));
  }
}
