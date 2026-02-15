import 'dart:convert';

import 'package:expencetracker/impVar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Usertransaction extends StatefulWidget {
  final String currentUserName;
  final String userId;
  final String userEmail;
  const Usertransaction({
    super.key,
    required this.currentUserName,
    required this.userId,
    required this.userEmail,
  });

  @override
  State<Usertransaction> createState() => _UsertransactionState();
}

bool isTracking = true;
TextEditingController expence = TextEditingController();
final GlobalKey<FormState> formKey = GlobalKey<FormState>();
List<Map<String, dynamic>> userAllDetailsList = [];
Map<String, dynamic>? userAllDetails;
String currentUserName = '';
String income = '';
Map<String, dynamic>? userInfo;
int totalUserBalance = 0;
int totalUserIncome = 0;
int totalUSerExpense = 0;

class _UsertransactionState extends State<Usertransaction> {
  void initState() {
    super.initState();
    // print('Current USer -> ${widget.currentUserName}');
    loadAllfunctions();
    // print('Current userId -> ${widget.userId}');
  }

  Future<void> loadAllfunctions() async {
    await fetchUserInfo(widget.userEmail);
    await fetchUserDetails(widget.userId);
    final useridd = userInfo?["id"];
    print(' useridd -> ${useridd}');
    await calculateTotalIncome();
    print('User Incomeee $totalUserBalance');
  }

  Future<void> calculateTotalIncome() async {
    int totalIncome = 0;
    int totalExpense = 0;
    for (var userAllDetails in userAllDetailsList) {
      if (widget.currentUserName == userAllDetails['to_user'] ||
          widget.currentUserName == userAllDetails['from_user']) {
        // total += (userAllDetails['letest_income'] as num?)?.toInt() ?? 500;
        totalIncome +=
            int.tryParse(userAllDetails['letest_income'] ?? '0') ?? 0;
        totalExpense +=
            int.tryParse(userAllDetails['letest_expence'] ?? '0') ?? 0;
      }
    }
    setState(() {
      totalUserIncome = totalIncome;
      totalUSerExpense = totalExpense;
      totalUserBalance = totalUserIncome - totalUSerExpense;
    });
  }

  String formatDateOrTime(String timeStringFromDB) {
    DateTime dateTime = DateTime.parse(timeStringFromDB).toLocal();
    DateTime now = DateTime.now();

    bool isToday = dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;

    if (isToday) {
      return DateFormat('hh:mm a').format(dateTime); // e.g., 01:43 PM
    } else {
      return DateFormat('MMM dd, yyyy').format(dateTime); // e.g., Aug 01, 2025
    }
  }

  Future<void> fetchUserInfo(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${server}showdata/userInfo'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({"email": email}),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody is List && responseBody.isNotEmpty) {
          final userInfoMap = responseBody[0] as Map<String, dynamic>;
          userInfo = userInfoMap;
          print(' user info response is -> ${userInfoMap}');
          // fetchUserDetails(userInfoMap['id'].toString());
        } else {
          print('No user found with this email');
        }
      } else {
        print('Failed to fetch user data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> fetchUserDetails(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('${server}showdata/userDetails'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({"userId": userId}),
      );
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody is List && responseBody.isNotEmpty) {
          final userAllDetail = responseBody[0] as Map<String, dynamic>;
          userAllDetails = userAllDetail;
          userAllDetailsList = List<Map<String, dynamic>>.from(responseBody);
          setState(() {});
          await calculateTotalIncome();
          // calculateTotalIncome();
        } else {
          print('Failed to fetch user details');
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  String getUserName(Map<String, dynamic> userAllDetails) {
    String userName = 'Name'; // Default
    if (userAllDetails['from_user'] != null &&
        userAllDetails['from_user'].isNotEmpty) {
      userName = userAllDetails['from_user'];
    } else if (userAllDetails['to_user'] != null &&
        userAllDetails['to_user'].isNotEmpty) {
      userName = userAllDetails['to_user'];
    }
    return userName;
  }

  Widget buildUserProfile(Map<String, dynamic> userAllDetails) {
    // Get user name
    String userName = 'Name'; // Default name
    if (userAllDetails['from_user'] != null &&
        userAllDetails['from_user'].toString().isNotEmpty) {
      userName = userAllDetails['from_user'];
    } else if (userAllDetails['to_user'] != null &&
        userAllDetails['to_user'].toString().isNotEmpty) {
      userName = userAllDetails['to_user'];
    }

    // Get user image
    String? userImage = userAllDetails['profile_image'];
    String firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : "U";

    return Row(
      children: [
        // Profile image with fallback
        if (userImage != null && userImage.isNotEmpty)
          CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(userImage),
          )
        else
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blueGrey,
            child: Text(
              firstLetter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(width: 10),

        // User details
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (() {
                String displayValue = '₹0'; // Default value

                if (userAllDetails['letest_income'] != null &&
                    userAllDetails['letest_income'].toString().isNotEmpty) {
                  displayValue = 'Received';
                } else if (userAllDetails['letest_expence'] != null &&
                    userAllDetails['letest_expence'].toString().isNotEmpty) {
                  displayValue = 'Sent';
                }

                return displayValue;
              })(),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              userAllDetails['TIMEDATE'] != null
                  ? formatDateOrTime(userAllDetails['TIMEDATE'])
                  : '',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Transaction History',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromARGB(255, 1, 65, 117),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      color: Colors.green,
                      size: 17,
                    ),
                    SizedBox(
                      width: 3,
                    ),
                    Text(
                      'Income',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '₹$totalUserIncome.00',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      color: Colors.red,
                      size: 17,
                    ),
                    SizedBox(
                      width: 3,
                    ),
                    Text(
                      'Expense',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '₹$totalUSerExpense.00',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.wallet,
                      color: Colors.yellow,
                      size: 17,
                    ),
                    SizedBox(
                      width: 3,
                    ),
                    Text(
                      'Total Balance ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '₹$totalUserBalance.00',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          // Start
          child: Column(
            children: [
              Container(
                height: 2.5,
                color: Colors.grey,
              ),
              SizedBox(
                height: 20,
              ),
              userAllDetailsList.isEmpty
                  ? Center(
                      child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 10.0),
                          child: Column(children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [],
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text('No Transaction History',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  // fontWeight: FontWeight.bold,
                                )),
                          ])),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${widget.currentUserName}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

              //User Transaction
              for (var userAllDetails in userAllDetailsList)
                if (widget.currentUserName == userAllDetails['to_user'] ||
                    widget.currentUserName == userAllDetails['from_user'])
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            buildUserProfile(userAllDetails),
                          ],
                        ),

                        Text(
                          (() {
                            String displayValue = '₹0'; // Default value

                            // Check if the income is present and not empty
                            if (userAllDetails['letest_income'] != null &&
                                userAllDetails['letest_income'].isNotEmpty) {
                              displayValue =
                                  '+ ₹${userAllDetails['letest_income']}';
                            }
                            // If income is not available, check for expense
                            else if (userAllDetails['letest_expence'] != null &&
                                userAllDetails['letest_expence'].isNotEmpty) {
                              displayValue =
                                  '- ₹${userAllDetails['letest_expence']}';
                            }

                            return displayValue;
                          })(),
                          style: TextStyle(
                            color: (() {
                              // Set color based on income or expense availability
                              if (userAllDetails['letest_income'] != null &&
                                  userAllDetails['letest_income'].isNotEmpty) {
                                return Colors.green;
                              } else if (userAllDetails['letest_expence'] !=
                                      null &&
                                  userAllDetails['letest_expence'].isNotEmpty) {
                                return Colors.red;
                              } else {
                                return Colors.black; // Default color
                              }
                            })(),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // letestIncome = userAllDetails['letest_income'] ?? 0,
                        // letestExpense = userAllDetails['letest_expense'] ?? 0,

                        // Text(
                        //   userAllDetails['letest_expense'] ?? '',
                        // )
                        // Text(
                        //   (() {
                        //     letestIncome =
                        //         userAllDetails['letest_income'] ?? '';
                        //     totalUserIncome += letestIncome;
                        //     // totalUserIncome = letestExpense + letestIncome;
                        //     return totalUserIncome;
                        //   })(),
                        //   style: TextStyle(
                        //     color: Colors.black,
                        //     fontSize: 16,
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
              // Text(
              //   (() {
              //     calculateTotalIncome();
              //     return totalUserIncome;
              //   })(),
              //   style: TextStyle(
              //     color: Colors.black,
              //     fontSize: 16,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              SizedBox(
                height: 20,
              ),
              SizedBox(
                height: 20,
              ),
              // TextButton(
              //     onPressed: () {
              //       calculateTotalIncome();
              //     },
              //     child: Text('Total User Income:')),
              // Text(
              //   'Total Income: ₹$totalUserIncome',
              //   style: TextStyle(
              //     fontSize: 18,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),

              // int total = 0;
              // Text('$totalUserBalance'),
            ],
          ),
        ),
      ),
      // floatingActionButton: Align(
      //   alignment: Alignment.center,
      //   child: Row(
      //     children: [
      //       Container(
      //           decoration: BoxDecoration(
      //             gradient: LinearGradient(
      //               begin: Alignment.topLeft,
      //               end: Alignment.bottomRight,
      //               colors: [Colors.blue, Colors.purple],
      //             ),
      //             borderRadius: BorderRadius.circular(10),
      //           ),
      //           child: ElevatedButton(
      //             onPressed: () {},
      //             child: Column(
      //               children: [
      //                 Text(
      //                   'Total balance:',
      //                   style: TextStyle(
      //                     color: Colors.white,
      //                   ),
      //                 ),
      //                 Text(
      //                   'Total balance: $totalUserBalance',
      //                   style: TextStyle(
      //                     color: Colors.white,
      //                   ),
      //                 )
      //               ],
      //             ),
      //           )),
      //       Container(
      //         decoration: BoxDecoration(
      //           gradient: LinearGradient(
      //             begin: Alignment.topLeft,
      //             end: Alignment.bottomRight,
      //             colors: [Colors.blue, Colors.purple],
      //           ),
      //           borderRadius: BorderRadius.circular(10),
      //         ),
      //         child: ElevatedButton(
      //           onPressed: () {
      //             showDialog(
      //               context: context,
      //               builder: (BuildContext context) {
      //                 expence.clear();
      //                 return AlertDialog(
      //                   backgroundColor: Colors
      //                       .transparent, // Make dialog background transparent
      //                   contentPadding:
      //                       EdgeInsets.zero, // Remove default padding
      //                   content: Container(
      //                     decoration: BoxDecoration(
      //                       gradient: LinearGradient(
      //                         begin: Alignment.topLeft,
      //                         end: Alignment.bottomRight,
      //                         colors: [Colors.blue, Colors.purple],
      //                       ),
      //                       borderRadius: BorderRadius.circular(12),
      //                     ),
      //                     child: Padding(
      //                       padding: EdgeInsets.all(16.0),
      //                       child: Column(
      //                         mainAxisSize: MainAxisSize.min,
      //                         children: [
      //                           Text(
      //                             'Send to ${widget.currentUserName}',
      //                             style: TextStyle(
      //                               fontSize: 20,
      //                               fontWeight: FontWeight.bold,
      //                               color: Colors.white,
      //                             ),
      //                           ),
      //                           SizedBox(height: 10),
      //                           Form(
      //                             key: formKey,
      //                             child: TextFormField(
      //                               controller: expence,
      //                               cursorColor: Colors.white,
      //                               style: TextStyle(color: Colors.white),
      //                               keyboardType:
      //                                   TextInputType.numberWithOptions(
      //                                       decimal:
      //                                           true), // Allow decimal input
      //                               decoration: InputDecoration(
      //                                 hintText: 'Enter Amount',
      //                                 hintStyle:
      //                                     TextStyle(color: Colors.white70),
      //                                 enabledBorder: UnderlineInputBorder(
      //                                   borderSide:
      //                                       BorderSide(color: Colors.white),
      //                                 ),
      //                                 focusedBorder: UnderlineInputBorder(
      //                                   borderSide:
      //                                       BorderSide(color: Colors.white),
      //                                 ),
      //                               ),
      //                               validator: (value) {
      //                                 if (value == null ||
      //                                     value.trim().isEmpty) {
      //                                   return 'Please enter an amount'; // Error if empty or whitespace
      //                                 }

      //                                 // Check if the input is a valid number
      //                                 final number = double.tryParse(value);
      //                                 if (number == null || number <= 0) {
      //                                   return 'Please enter a valid number greater than 0'; // Ensure it's a valid number and positive
      //                                 }
      //                                 return null;
      //                               },
      //                             ),
      //                           ),
      //                           SizedBox(height: 20),
      //                           Align(
      //                             alignment: Alignment.centerRight,
      //                             child: Row(
      //                               mainAxisAlignment: MainAxisAlignment.end,
      //                               children: [
      //                                 TextButton(
      //                                   child: Text(
      //                                     'Cancel',
      //                                     style: TextStyle(color: Colors.white),
      //                                   ),
      //                                   onPressed: () {
      //                                     Navigator.of(context).pop();
      //                                   },
      //                                 ),
      //                                 TextButton(
      //                                   child: Text(
      //                                     'send',
      //                                     style: TextStyle(color: Colors.white),
      //                                   ),
      //                                   onPressed: () {
      //                                     insertUserIncome();
      //                                   },
      //                                 ),
      //                               ],
      //                             ),
      //                           ),
      //                         ],
      //                       ),
      //                     ),
      //                   ),
      //                 );
      //               },
      //             );
      //           },
      //           style: ElevatedButton.styleFrom(
      //             backgroundColor: Colors.transparent,
      //             foregroundColor: Colors.white,
      //             shadowColor: Colors.transparent,
      //             elevation: 5,
      //             padding: EdgeInsets.symmetric(
      //               horizontal: MediaQuery.of(context).size.width * 0.025,
      //             ),
      //             textStyle: TextStyle(
      //               fontSize: 15,
      //               fontWeight: FontWeight.bold,
      //             ),
      //             shape: RoundedRectangleBorder(
      //               borderRadius: BorderRadius.circular(10),
      //             ),
      //           ),
      //           child: Text('Send Again'),
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}
