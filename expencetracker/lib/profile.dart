import 'dart:convert';
import 'dart:io';

import 'package:expencetracker/impVar.dart';
import 'package:expencetracker/mainPage.dart';
import 'package:expencetracker/utils/loading_fallback_widget.dart';
import 'package:expencetracker/utils/routes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Profile extends StatefulWidget {
  final String userEmail;

  const Profile({super.key, required this.userEmail});

  @override
  State<Profile> createState() => _ProfileState();
}

PlatformFile? pickedFile;

class _ProfileState extends State<Profile> {
  Map<String, dynamic>? userInfo;
  bool isEditing = false;
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController image = TextEditingController();
  bool showButton = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    setState(() {
      isLoading = true;
    });

    try {
      await fetchUserInfo(widget.userEmail);
    } catch (e) {
      print('Error loading user info: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logout(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('email'); // clear saved email
    Navigator.pushReplacementNamed(context, MyRoutes.Login);
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          pickedFile = result.files.first;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _saveImage() async {
    if (pickedFile == null) return;
    await updateUser();
    setState(() {
      pickedFile = null;
    });
  }

  Future<void> fetchUserInfo(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${server}showdata/userInfo'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"email": email}),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody is List && responseBody.isNotEmpty) {
          setState(() {
            userInfo = responseBody[0] as Map<String, dynamic>;
          });
          print('User info loaded -> $userInfo');
        } else {
          print('No user found ->');
        }
      } else {
        print('Failed to load user info');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  //Update Profile

  Future<void> updateUser() async {
    try {
      final updatedName = name.text.isNotEmpty ? name.text : userInfo?['name'];
      final updatedPhone =
          phone.text.isNotEmpty ? phone.text : userInfo?['phone'];
      final userEmail = userInfo?['email'];
      var uri = Uri.parse('${server}showdata/profile/update');
      var request = http.MultipartRequest('POST', uri);

      request.fields['name'] = updatedName ?? '';
      request.fields['phone'] = updatedPhone ?? '';
      request.fields['email'] = userEmail ?? '';

      if (pickedFile != null && pickedFile!.path != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          pickedFile!.path!,
        ));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBodyString = await response.stream.bytesToString();
        final responseBody = json.decode(responseBodyString);

        if (responseBody['status'] == 'success') {
          String? newImagePath = responseBody['image'];

          setState(() {
            isEditing = false;
            userInfo = {
              'name': updatedName,
              'phone': updatedPhone,
              'email': userEmail,
              'image': newImagePath ??
                  userInfo?['image'], // Use old image if not updated
            };
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    MainPage(currentIndex: 4, userEmail: userEmail)),
          );
        } else {
          print('Failed to update user details');
        }
      } else {
        print('Failed to update user details: ${response.statusCode}');
      }
    } catch (err) {
      print('Error: $err');
    }
  }

  Future<void> updateImage() async {}

  Widget buildInfoRow(IconData icon, TextEditingController controller,
      String? value, bool isEditing, String placeholder) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 15,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.black),
                SizedBox(width: 10),
                isEditing
                    ? Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: placeholder,
                            hintStyle: TextStyle(color: Colors.grey),
                            // labelText: placeholder,
                            // labelStyle: TextStyle(color: Colors.grey),
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
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8.0),
                          ),
                        ),
                      )
                    : Text(
                        value ?? 'Not available',
                        style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ],
            ),
          ),
          SizedBox(height: 15),
          Divider(color: Colors.grey),
          SizedBox(height: 15),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Stack(
                children: [
                  //Container 1
                  Container(
                    width: MediaQuery.of(context).size.width * 3,
                    height: MediaQuery.of(context).size.height * 0.33,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  //Container 2
                  Positioned(
                    top: -270,
                    left: -50,
                    child: Container(
                      width: 500, // Must be square for a perfect circle
                      height: 500,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue,
                            Colors.purple,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 150,
                    right: 130,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: (pickedFile != null)
                          ? FileImage(File(pickedFile!.path!))
                          : (userInfo?['image'] != null &&
                                  userInfo!['image']
                                      .toString()
                                      .trim()
                                      .isNotEmpty &&
                                  userInfo!['image']
                                          .toString()
                                          .trim()
                                          .toLowerCase() !=
                                      'null')
                              ? NetworkImage(
                                  '${server}${userInfo!['image']}'
                                      .replaceAll('\\', '/'),
                                ) as ImageProvider
                              : const NetworkImage(
                                  'https://img.freepik.com/free-vector/blue-circle-with-white-user_78370-4707.jpg',
                                ),
                    ),
                  ),
                  // //Logout Button
                  // Positioned(
                  //   top: 30,
                  //   right: 10,
                  //   child: GestureDetector(
                  //     onTap: _pickImage,
                  //     child: Container(
                  //       decoration: BoxDecoration(
                  //         shape: BoxShape.circle,
                  //         color: Colors.red,
                  //         border: Border.all(color: Colors.white, width: 2),
                  //       ),
                  //       padding: const EdgeInsets.all(6),
                  //       child: const Icon(
                  //         Icons.logout,
                  //         color: Colors.white,
                  //         size: 22,
                  //       ),
                  //     ),
                  //   ),
                  // ),

                  //Edit Icon
                  if (isEditing)
                    Positioned(
                      top: 150,
                      right: 130,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),

                  if (pickedFile != null)
                    Positioned(
                      top: 150,
                      right: 130,
                      child: GestureDetector(
                        onTap: _saveImage,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.save,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  if (pickedFile != null)
                    Positioned(
                      top: 230,
                      right: 130, // moved slightly left from save
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            pickedFile = null; // cancel image selection
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 15,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LoadingFallbackWidget(
                      isLoading: isLoading,
                      hasData: userInfo?['name'] != null,
                      onReload: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainPage(
                              currentIndex: 4,
                              userEmail: widget.userEmail,
                            ),
                          ),
                        );
                      },
                      fallbackMessage: 'Profile information not available',
                      child: SizedBox(),
                    ),
                    // Divider(
                    //   height: 5,
                    // ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        Text('Personal Information:',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 30,
              ),
              buildInfoRow(
                  Icons.person,
                  name,
                  userInfo?['name'] ?? 'Not available',
                  isEditing,
                  userInfo?['name'] ?? 'Not available'),
              buildInfoRow(
                  Icons.phone,
                  phone,
                  userInfo?['phone'] ?? 'Not available',
                  isEditing,
                  userInfo?['phone'] ?? 'Not available'),
              buildInfoRow(
                  Icons.email, email, userInfo?['email'], false, 'Email'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    isEditing
                        ? Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isEditing = false;
                                    updateUser();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 5,
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        MediaQuery.of(context).size.width *
                                            0.03,
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text('Save'),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isEditing = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  elevation: 5,
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        MediaQuery.of(context).size.width *
                                            0.03,
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text('Cancel'),
                              ),
                            ],
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.blue, Colors.purple],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isEditing = true; // Enter editing mode
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                elevation: 5,
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.025,
                                ),
                                textStyle: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text('Edit Profile'),
                            ),
                          ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue, Colors.purple],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // Dialog logic
                          Widget cancelButton = TextButton(
                            style: TextButton.styleFrom(
                              // backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "No",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          );

                          Widget continueButton = ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text("Yes"),
                            onPressed: () async {
                              await logout(context);
                            },
                          );

                          Dialog alert = Dialog(
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.blue, Colors.purple],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.logout_outlined,
                                          color: Colors.redAccent),
                                      SizedBox(width: 10),
                                      Text(
                                        "Confirm Logout",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "Do you want to log out?",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                                  SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      cancelButton,
                                      SizedBox(width: 10),
                                      continueButton
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );

                          showDialog(
                            context: context,
                            builder: (BuildContext context) => alert,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.025,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout_outlined,
                                color: Colors.white, size: 18),
                            SizedBox(width: 5),
                            Text('Logout',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 30,
              ),

              //Start
            ],
          ),
        ),
      ),
    );
  }
}
