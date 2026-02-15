import 'dart:convert';
import 'dart:io';

import 'package:expencetracker/impVar.dart';
import 'package:expencetracker/login.dart';
import 'package:expencetracker/utils/routes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  bool viewpass = true;
  bool viewpass2 = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController pass = TextEditingController();
  TextEditingController confirmpass = TextEditingController();
  String? emailError;
  PlatformFile? pickedFile;
  // final path = pickedFile?.path;

  String namehint = 'Name';
  String emailhint = 'Email';
  String phonehint = 'Phone';
  String passhint = 'Password';
  String cnfpasshint = 'Confirm Password';
  bool emailExists = false;
  bool isLoading = false;
  String errorMessage = '';

  void passwordvisibility() {
    setState(() {
      viewpass = !viewpass;
    });
  }

  void passwordvisibility2() {
    setState(() {
      viewpass2 = !viewpass2;
    });
  }

  void checkInput() {
    if (_formKey.currentState!.validate()) {
      signupUser();
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${server}signup/signupuser'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['email_exists'];
      } else {
        throw Exception('Failed to check email existence');
      }
    } catch (error) {
      emailError = 'Email already exists';
      print('Error checking email existence: $error');
      return false;
    }
  }

  Future<void> signupUser() async {
    setState(() {
      isLoading = true;
      errorMessage = ''; // Reset any previous error message
    });
    Future.delayed(Duration(seconds: 5), () {
      if (isLoading) {
        setState(() {
          errorMessage = 'Server is not responding...';
          isLoading = false; // Stop the loading indicator after 3 seconds
        });
      }
    });

    bool emailExists = await checkEmailExists(email.text);
    if (emailExists) {
      setState(() {
        emailError = 'Email already exists, try a different email';
      });
      return;
    }

    try {
      var uri = Uri.parse('${server}signup/signupuser/insert');
      var request = http.MultipartRequest('POST', uri);

      // Add text fields
      request.fields['name'] = name.text;
      request.fields['email'] = email.text;
      request.fields['phone'] = phone.text;
      request.fields['password'] = pass.text;

      if (pickedFile != null && pickedFile!.path != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file', // This must match multer's field name: upload.single('file')
          pickedFile!.path!,
        ));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        print("User registered successfully");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => Login()),
        );
      } else {
        setState(() {
          errorMessage = 'Server is not responding...';
        });
        print('Failed to register user: ${response.statusCode}');
      }
    } catch (error) {
      print('Sign up error: $error');
      setState(() {
        errorMessage = 'Server is not responding...';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          pickedFile = result.files.first;
          print('Picked file: ${pickedFile}');
        });
      }
    } catch (error) {
      print('Error picking image: $error');
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
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue, Colors.purple],
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
              child: Text(
                'Sign Up',
                style: GoogleFonts.raleway(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color:
                      Colors.white, // Color must be set for ShaderMask to work
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            GestureDetector(
                onTap: _pickImage,
                child: Stack(alignment: Alignment.center, children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey,
                    child: pickedFile != null
                        ? ClipOval(
                            child: Image.file(
                              File(pickedFile!.path!),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                  ),
                  Positioned(
                      top: 0,
                      left: 65,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ))
                ])),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    //Name Field
                    TextFormField(
                      controller: name,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        prefixIcon: Icon(Icons.person),
                        fillColor: Colors.grey[100],
                        filled: true,
                        hintText: 'Name',
                        labelText: 'Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      controller: email,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey, width: 2),
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
                        hintText: "Email",
                        labelText: "Email",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        final emailRegExp =
                            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                        if (!emailRegExp.hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        prefixIcon: Icon(Icons.phone),
                        fillColor: Colors.grey[100],
                        filled: true,
                        hintText: "Phone",
                        labelText: "Phone",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length != 10) {
                          return 'Phone number must be 10 digits';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: pass,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: viewpass,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock),
                        fillColor: Colors.grey[100],
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        hintText: "Create Password",
                        labelText: "Password",
                        suffixIcon: IconButton(
                          icon: Icon(viewpass
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: passwordvisibility,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please create a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      obscureText: viewpass2,
                      controller: confirmpass,
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
                          borderSide: BorderSide(color: Colors.grey, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        hintText: "Confirm Password",
                        labelText: "Confirm Password",
                        suffixIcon: IconButton(
                          icon: Icon(viewpass2
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: passwordvisibility2,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != pass.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              //column
            ),
            SizedBox(
              height: 20,
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
                onPressed: checkInput,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  padding: EdgeInsets.symmetric(horizontal: 130, vertical: 15),
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
                        "Signup",
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Ensure contrast over gradient
                        ),
                      ),
              ),
            ),
            SizedBox(
              height: 20,
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
                          Navigator.pushNamedAndRemoveUntil(
                              context, MyRoutes.Signup, (route) => false);
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
                  "Click here to",
                  style: GoogleFonts.raleway(
                      // fontWeight: FontWeight.bold,
                      // color: Colors.red,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigator.pushNamed(context, MyRoutes.Login);
                    Navigator.pushNamedAndRemoveUntil(
                        context, MyRoutes.Login, (route) => false);
                  },
                  child: Text(
                    'Login',
                    style: GoogleFonts.raleway(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                )
              ],
            ),
          ],
        )),
      ),
    );
  }
}
