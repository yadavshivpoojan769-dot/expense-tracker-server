import 'dart:convert';

import 'package:expencetracker/mainPage.dart';
import 'package:expencetracker/seeAll.dart';
import 'package:expencetracker/seeAllSendAgain.dart';
import 'package:expencetracker/userTransaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Homepage extends StatefulWidget {
  final String userEmail; // <-- new
  const Homepage({super.key, required this.userEmail});

  @override
  State<Homepage> createState() => _HomepageState();
}

bool addIncome = false;
bool addExpence = false;
bool showAllDetails = false;
final GlobalKey<FormState> _incomeFormKey = GlobalKey<FormState>();
final GlobalKey<FormState> _expenseFormKey = GlobalKey<FormState>();

class _HomepageState extends State<Homepage> {
  Map<String, dynamic>? userInfo;
  Map<String, dynamic>? userAllDetails;
  List<Map<String, dynamic>> userAllDetailsList = [];

  String imageUrl = '';
  TextEditingController income = TextEditingController();
  TextEditingController fromUSer = TextEditingController();
  TextEditingController toUser = TextEditingController();
  TextEditingController expence = TextEditingController();
  TextEditingController letest_income = TextEditingController();
  TextEditingController letest_expence = TextEditingController();
  int Income = 0;
  int balance = 0;
  bool incomeFocus = false;
  String currentUserName = '';
  bool showButton = false;

  void initState() {
    super.initState();
    print('first email -> ${widget.userEmail}');

    // Call your loading function
    loadAllfunctions();

    // Start a timer to do something after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      // Example: setState to show a button or trigger something
      setState(() {
        showButton = true; // Make sure you declared this bool in your state
      });
    });
  }

  String formatTime(String timeStringFromDB) {
    DateTime dateTime =
        DateTime.parse(timeStringFromDB).toLocal(); // Convert to local time
    return DateFormat('hh:mm a').format(dateTime); // Format to 01:43 PM
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

  void totalIncome(int Income) {
    setState(() {
      Income = Income + int.parse(income.text);
    });
  }

  Future<void> loadAllfunctions() async {
    await fetchUserInfo(widget.userEmail);
    final useridd = userInfo?["id"];
    print(' useridd -> ${useridd}');
    await limitedUserDetails('$useridd');
    // await fetchUserDetails('$useridd');
    await totalBalance();
    await fatchTransaction();
    // print('Transaction name is' + userAllDetails?['from_user'] + 'MMMMM');
    // print('Transaction name is' + userAllDetails?['to_user'] + 'YYYYY');
  }

  Future<void> fatchTransaction() async {
    setState(() {
      if (userAllDetails?['to_user'] == '') {
        addIncome = true;
        addExpence = false;
      } else if (userAllDetails?['from_user'] == '') {
        addIncome = false;
        addExpence = true;
      }
    });
  }

  Future<List<String>> fetchSuggestion(String query) async {
    // Extract all names from both 'from_user' and 'to_user' in userAllDetailsList
    final allNames = <String>{}; // Use a Set to avoid duplicates

    for (var detail in userAllDetailsList) {
      final from = detail['from_user']?.toString().trim();
      final to = detail['to_user']?.toString().trim();

      if (from != null && from.isNotEmpty) {
        allNames.add(from);
      }
      if (to != null && to.isNotEmpty) {
        allNames.add(to);
      }
    }

    // Convert Set to List and filter by query
    final filtered = allNames
        .where((name) => name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    // Optionally sort alphabetically
    filtered.sort();

    // Also do your logic for income/expense switch if needed
    setState(() {
      if (userAllDetails?['to_user'] == '') {
        addIncome = true;
        addExpence = false;
      } else if (userAllDetails?['from_user'] == '') {
        addIncome = false;
        addExpence = true;
      }
    });

    return filtered;
  }

  Future<void> totalBalance() async {
    setState(() {
      balance =
          (userAllDetails?['income'] ?? 0) - (userAllDetails?['expence'] ?? 0);
    });
  }

  Future<void> fetchUserInfo(String email) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.252:55000/showdata/userInfo'),
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

  Future<void> limitedUserDetails(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.252:55000/showdata/limiteduserDetails'),
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
          // print('User All Details-> ${userAllDetailsList}');
          // print('User Details -> ${userAllDetails}');
        } else {
          print('Failed to fetch user details');
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  Future<void> insertUserIncome() async {
    int previousIncome = userAllDetails?['income'] ?? 0;
    int previousExpence = userAllDetails?['expence'] ?? 0;
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.252:55000/userdetails/insert'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "income": int.tryParse(income.text.trim()) != null
              ? int.parse(income.text.trim()) + previousIncome
              : previousIncome,
          "from_user": fromUSer.text,
          "expence": int.tryParse(expence.text.trim()) != null
              ? int.parse(expence.text.trim()) + previousExpence
              : previousExpence,
          "to_user": toUser.text,
          "letest_income": income.text,
          "letest_expence": expence.text,
          "userId": userInfo?['id'],
        }),
      );
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody == 'success') {
          print("User details mul gya hai");
          await limitedUserDetails((userInfo?['id']).toString());
          await totalBalance();
          Navigator.of(context).pop();
        } else {
          print('Failed to insert user details');
        }
      } else {
        print('Failed to insert user details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error inserting user details: $e');
    }
  }

  //Add Income ShowDilog
  Future<void> showAddIncomeDialog({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required TextEditingController incomeController,
    required TextEditingController fromUserController,
    required Future<List<String>> Function(String) fetchSuggestion,
    required VoidCallback onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue, Colors.purple],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Income',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: incomeController,
                          cursorColor: Colors.white,
                          style: TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter Amount',
                            hintStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter amount';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        TypeAheadField<String>(
                          controller: fromUserController,
                          suggestionsCallback: fetchSuggestion,
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              title: Text(
                                suggestion,
                                style: TextStyle(color: Colors.black),
                              ),
                            );
                          },
                          onSelected: (suggestion) {
                            fromUserController.text = suggestion;
                            FocusScope.of(context).unfocus();
                          },
                          emptyBuilder: (context) => SizedBox.shrink(),
                          builder: (context, controller, focusNode) {
                            return Row(
                              children: [
                                Expanded(
                                  child: Builder(
                                    builder: (context) {
                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        cursorColor: Colors.white,
                                        style: TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'From',
                                          hintStyle:
                                              TextStyle(color: Colors.white70),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.white),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.white),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // IconButton(
                                //   onPressed: () {
                                //     FocusScope.of(context)
                                //         .requestFocus(FocusNode());
                                //   },
                                //   icon: Icon(Icons.add,
                                //       color: Colors.white),
                                // ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 10),
                    TextButton(
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          onSubmit();
                        }
                      },
                      child: Text(
                        'Add',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //Add Expense Dialouge
  Future<void> showAddExpenseDialog({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required TextEditingController expenseController,
    required TextEditingController toUserController,
    required Future<List<String>> Function(String) fetchSuggestion,
    required VoidCallback onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue, Colors.purple],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add Expense',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: expenseController,
                          cursorColor: Colors.white,
                          style: TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter Amount',
                            hintStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter amount';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        TypeAheadField<String>(
                          controller: toUserController,
                          suggestionsCallback: fetchSuggestion,
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              title: Text(
                                suggestion,
                                style: TextStyle(color: Colors.black),
                              ),
                            );
                          },
                          onSelected: (suggestion) {
                            toUserController.text = suggestion;
                            FocusScope.of(context).unfocus();
                          },
                          emptyBuilder: (context) => SizedBox.shrink(),
                          builder: (context, controller, focusNode) {
                            return Row(
                              children: [
                                Expanded(
                                  child: Builder(
                                    builder: (context) {
                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        cursorColor: Colors.white,
                                        style: TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'To',
                                          hintStyle:
                                              TextStyle(color: Colors.white70),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.white),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.white),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // IconButton(
                                //   onPressed: () {
                                //     FocusScope.of(context)
                                //         .requestFocus(FocusNode());
                                //   },
                                //   icon: Icon(Icons.add, color: Colors.white),
                                // ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          // currentUserName = '';
                          expence.clear();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: 10),
                      TextButton(
                        onPressed: () {
                          // currentUserName = '';
                          // expence.clear();
                          // expenseController.clear();
                          if (formKey.currentState!.validate()) {
                            onSubmit();
                          }
                        },
                        child: Text(
                          'Add',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // fetchUserInfo(widget.userEmail);
    print('inside build context ${userInfo?['name'] ?? 'UserName'}');
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
                    height: MediaQuery.of(context).size.height * 0.38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  //Container 2
                  Positioned(
                    top: -200,
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
                            const Color.fromARGB(255, 40, 7, 46),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            userInfo?['name'] != null
                                ? Text(
                                    '${userInfo!['name']}',
                                    style: TextStyle(
                                      color: Colors.yellow,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : showButton
                                    ? Row(
                                        children: [
                                          Text(
                                            'Server not connected tap to',
                                            style:
                                                TextStyle(color: Colors.yellow),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        MainPage(
                                                            currentIndex: 0,
                                                            userEmail: widget
                                                                .userEmail)),
                                              );
                                            },
                                            child: Text(
                                              'reload',
                                              style: TextStyle(
                                                color: Colors.yellow,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.yellow,
                                        ),
                                      ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.notifications_sharp),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: Colors
                                      .transparent, // Make dialog background transparent
                                  contentPadding:
                                      EdgeInsets.zero, // Remove default padding
                                  content: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Colors.blue, Colors.purple],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Notifications',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            "You don't have notifications",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 20),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              child: Text(
                                                'OK',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          color: Colors.white,
                        )
                      ],
                    ),
                  ),

                  Positioned(
                      top: 110,
                      left: 20,
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.23,
                        width: MediaQuery.of(context).size.width * 0.9,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.blue, Colors.purple],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset:
                                  Offset(0, 3), // changes position of shadow
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.wallet,
                                      color: Colors.white,
                                      size: 24, // increase size from 20 to 24
                                    ),
                                    Text(' Total Balance',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        )),
                                  ],
                                ),

                                //Call this
                                PopupMenuButton<String>(
                                  color: Colors.white,
                                  onSelected: (String value) {
                                    //Add Income
                                    income.clear();
                                    fromUSer.clear();
                                    toUser.clear();
                                    expence.clear();
                                    if (value == 'Add Income') {
                                      showAddIncomeDialog(
                                        context: context,
                                        formKey: _incomeFormKey,
                                        incomeController: income,
                                        fromUserController: fromUSer,
                                        fetchSuggestion:
                                            fetchSuggestion, // your async suggestion method
                                        onSubmit: () {
                                          insertUserIncome(); // your logic to save data
                                          // Navigator.of(context).pop();
                                        },
                                      );
                                      // showDialog(
                                      //   context: context,
                                      //   builder: (BuildContext context) {
                                      //     return Dialog(
                                      //       backgroundColor: Colors
                                      //           .transparent, // Transparent to show gradient
                                      //       shape: RoundedRectangleBorder(
                                      //         borderRadius:
                                      //             BorderRadius.circular(16),
                                      //       ),
                                      //       child: Container(
                                      //         decoration: BoxDecoration(
                                      //           gradient: LinearGradient(
                                      //             begin: Alignment.topLeft,
                                      //             end: Alignment.bottomRight,
                                      //             colors: [
                                      //               Colors.blue,
                                      //               Colors.purple
                                      //             ],
                                      //           ),
                                      //           borderRadius:
                                      //               BorderRadius.circular(16),
                                      //         ),
                                      //         padding: EdgeInsets.all(20),
                                      //         child: Column(
                                      //           mainAxisSize: MainAxisSize.min,
                                      //           children: [
                                      //             Text(
                                      //               'Add Income',
                                      //               style: TextStyle(
                                      //                 color: Colors.white,
                                      //                 fontSize: 20,
                                      //                 fontWeight:
                                      //                     FontWeight.bold,
                                      //               ),
                                      //             ),
                                      //             SizedBox(height: 20),
                                      //             Form(
                                      //               key: _incomeFormKey,
                                      //               child:
                                      //                   SingleChildScrollView(
                                      //                 child: Column(
                                      //                   children: [
                                      //                     TextFormField(
                                      //                       controller: income,
                                      //                       cursorColor:
                                      //                           Colors.white,
                                      //                       style: TextStyle(
                                      //                           color: Colors
                                      //                               .white),
                                      //                       keyboardType:
                                      //                           TextInputType
                                      //                               .number,
                                      //                       decoration:
                                      //                           InputDecoration(
                                      //                         hintText:
                                      //                             'Enter Amount',
                                      //                         hintStyle: TextStyle(
                                      //                             color: Colors
                                      //                                 .white70),
                                      //                         enabledBorder:
                                      //                             UnderlineInputBorder(
                                      //                           borderSide: BorderSide(
                                      //                               color: Colors
                                      //                                   .white),
                                      //                         ),
                                      //                         focusedBorder:
                                      //                             UnderlineInputBorder(
                                      //                           borderSide: BorderSide(
                                      //                               color: Colors
                                      //                                   .white),
                                      //                         ),
                                      //                       ),
                                      //                       validator: (value) {
                                      //                         if (value ==
                                      //                                 null ||
                                      //                             value
                                      //                                 .trim()
                                      //                                 .isEmpty) {
                                      //                           return 'Please enter amount';
                                      //                         }
                                      //                         return null;
                                      //                       },
                                      //                     ),
                                      //                     SizedBox(height: 10),
                                      //                     TypeAheadField<
                                      //                         String>(
                                      //                       controller:
                                      //                           fromUSer,
                                      //                       suggestionsCallback:
                                      //                           (pattern) async {
                                      //                         return await fetchSuggestion(
                                      //                             pattern);
                                      //                       },
                                      //                       itemBuilder:
                                      //                           (context,
                                      //                               suggestion) {
                                      //                         return ListTile(
                                      //                           title: Text(
                                      //                             suggestion,
                                      //                             style: TextStyle(
                                      //                                 color: Colors
                                      //                                     .black),
                                      //                           ),
                                      //                         );
                                      //                       },
                                      //                       onSelected:
                                      //                           (suggestion) {
                                      //                         fromUSer.text =
                                      //                             suggestion;
                                      //                         FocusScope.of(
                                      //                                 context)
                                      //                             .requestFocus(
                                      //                                 FocusNode());
                                      //                       },
                                      //                       emptyBuilder:
                                      //                           (context) {
                                      //                         return SizedBox
                                      //                             .shrink();
                                      //                       },
                                      //                       builder: (context,
                                      //                           controller,
                                      //                           focusNode) {
                                      //                         return Row(
                                      //                           children: [
                                      //                             Expanded(
                                      //                               child:
                                      //                                   TextField(
                                      //                                 controller:
                                      //                                     controller,
                                      //                                 focusNode:
                                      //                                     focusNode,
                                      //                                 cursorColor:
                                      //                                     Colors
                                      //                                         .white,
                                      //                                 style: TextStyle(
                                      //                                     color:
                                      //                                         Colors.white),
                                      //                                 decoration:
                                      //                                     InputDecoration(
                                      //                                   hintText:
                                      //                                       'From',
                                      //                                   hintStyle:
                                      //                                       TextStyle(color: Colors.white70),
                                      //                                   enabledBorder:
                                      //                                       UnderlineInputBorder(
                                      //                                     borderSide:
                                      //                                         BorderSide(color: Colors.white),
                                      //                                   ),
                                      //                                   focusedBorder:
                                      //                                       UnderlineInputBorder(
                                      //                                     borderSide:
                                      //                                         BorderSide(color: Colors.white),
                                      //                                   ),
                                      //                                 ),
                                      //                               ),
                                      //                             ),
                                      //                             IconButton(
                                      //                                 onPressed:
                                      //                                     () {
                                      //                                   FocusScope.of(context)
                                      //                                       .requestFocus(FocusNode());
                                      //                                 },
                                      //                                 icon:
                                      //                                     Icon(
                                      //                                   Icons
                                      //                                       .arrow_downward,
                                      //                                   color: Colors
                                      //                                       .white,
                                      //                                 ))
                                      //                           ],
                                      //                         );
                                      //                       },
                                      //                     ),
                                      //                   ],
                                      //                 ),
                                      //               ),
                                      //             ),
                                      //             SizedBox(height: 20),
                                      //             Row(
                                      //               mainAxisAlignment:
                                      //                   MainAxisAlignment.end,
                                      //               children: [
                                      //                 TextButton(
                                      //                   style: TextButton
                                      //                       .styleFrom(
                                      //                     foregroundColor:
                                      //                         Colors.white,
                                      //                   ),
                                      //                   onPressed: () {
                                      //                     Navigator.of(context)
                                      //                         .pop();
                                      //                   },
                                      //                   child: Text(
                                      //                     'Cancel',
                                      //                     style: TextStyle(
                                      //                       color: Colors.white,
                                      //                       fontWeight:
                                      //                           FontWeight.bold,
                                      //                     ),
                                      //                   ),
                                      //                 ),
                                      //                 SizedBox(width: 10),
                                      //                 TextButton(
                                      //                   style: TextButton
                                      //                       .styleFrom(
                                      //                     foregroundColor:
                                      //                         Colors.white,
                                      //                   ),
                                      //                   onPressed: () {
                                      //                     if (_incomeFormKey
                                      //                         .currentState!
                                      //                         .validate()) {
                                      //                       insertUserIncome();
                                      //                     }
                                      //                   },
                                      //                   child: Text(
                                      //                     'Add',
                                      //                     style: TextStyle(
                                      //                       color: Colors.white,
                                      //                       fontWeight:
                                      //                           FontWeight.bold,
                                      //                     ),
                                      //                   ),
                                      //                 ),
                                      //               ],
                                      //             ),
                                      //           ],
                                      //         ),
                                      //       ),
                                      //     );
                                      //   },
                                      // );

                                      //Add Expense
                                    } else if (value == 'Add Expense') {
                                      showAddExpenseDialog(
                                        context: context,
                                        formKey: _expenseFormKey,
                                        expenseController: expence,
                                        toUserController: toUser,
                                        fetchSuggestion: fetchSuggestion,
                                        onSubmit: () {
                                          insertUserIncome(); // Or your actual expense saving logic
                                        },
                                      );
                                      //Shoow
                                      // showDialog(
                                      //   context: context,
                                      //   builder: (BuildContext context) {
                                      //     return Dialog(
                                      //       backgroundColor: Colors.transparent,
                                      //       shape: RoundedRectangleBorder(
                                      //           borderRadius:
                                      //               BorderRadius.circular(16)),
                                      //       child: Container(
                                      //         decoration: BoxDecoration(
                                      //           gradient: LinearGradient(
                                      //             begin: Alignment.topLeft,
                                      //             end: Alignment.bottomRight,
                                      //             colors: [
                                      //               Colors.blue,
                                      //               Colors.purple
                                      //             ],
                                      //           ),
                                      //           borderRadius:
                                      //               BorderRadius.circular(16),
                                      //         ),
                                      //         padding: EdgeInsets.all(20),
                                      //         child: SingleChildScrollView(
                                      //           child: Column(
                                      //             mainAxisSize:
                                      //                 MainAxisSize.min,
                                      //             children: [
                                      //               Text(
                                      //                 'Add Expense',
                                      //                 style: TextStyle(
                                      //                   color: Colors.white,
                                      //                   fontSize: 20,
                                      //                   fontWeight:
                                      //                       FontWeight.bold,
                                      //                 ),
                                      //               ),
                                      //               SizedBox(height: 20),
                                      //               Form(
                                      //                 key: _expenseFormKey,
                                      //                 child: Column(
                                      //                   children: [
                                      //                     TextFormField(
                                      //                       controller: expence,
                                      //                       cursorColor:
                                      //                           Colors.white,
                                      //                       style: TextStyle(
                                      //                           color: Colors
                                      //                               .white),
                                      //                       keyboardType:
                                      //                           TextInputType
                                      //                               .number,
                                      //                       decoration:
                                      //                           InputDecoration(
                                      //                         hintText:
                                      //                             'Enter Amount',
                                      //                         hintStyle: TextStyle(
                                      //                             color: Colors
                                      //                                 .white70),
                                      //                         enabledBorder:
                                      //                             UnderlineInputBorder(
                                      //                           borderSide: BorderSide(
                                      //                               color: Colors
                                      //                                   .white),
                                      //                         ),
                                      //                         focusedBorder:
                                      //                             UnderlineInputBorder(
                                      //                           borderSide: BorderSide(
                                      //                               color: Colors
                                      //                                   .white),
                                      //                         ),
                                      //                       ),
                                      //                       validator: (value) {
                                      //                         if (value ==
                                      //                                 null ||
                                      //                             value
                                      //                                 .trim()
                                      //                                 .isEmpty) {
                                      //                           return 'Please enter amount';
                                      //                         }
                                      //                         return null;
                                      //                       },
                                      //                     ),
                                      //                     SizedBox(height: 10),
                                      //                     TypeAheadField<
                                      //                         String>(
                                      //                       controller: toUser,
                                      //                       suggestionsCallback:
                                      //                           (pattern) async {
                                      //                         return await fetchSuggestion(
                                      //                             pattern);
                                      //                       },
                                      //                       itemBuilder:
                                      //                           (context,
                                      //                               suggestion) {
                                      //                         return ListTile(
                                      //                           title: Text(
                                      //                             suggestion,
                                      //                             style: TextStyle(
                                      //                                 color: Colors
                                      //                                     .black),
                                      //                           ),
                                      //                         );
                                      //                       },
                                      //                       onSelected:
                                      //                           (suggestion) {
                                      //                         toUser.text =
                                      //                             suggestion;
                                      //                         FocusScope.of(
                                      //                                 context)
                                      //                             .unfocus();
                                      //                       },
                                      //                       emptyBuilder:
                                      //                           (context) {
                                      //                         return SizedBox
                                      //                             .shrink();
                                      //                       },
                                      //                       builder: (context,
                                      //                           controller,
                                      //                           focusNode) {
                                      //                         return Row(
                                      //                           children: [
                                      //                             Expanded(
                                      //                               child:
                                      //                                   TextField(
                                      //                                 controller:
                                      //                                     controller,
                                      //                                 focusNode:
                                      //                                     focusNode,
                                      //                                 cursorColor:
                                      //                                     Colors
                                      //                                         .white,
                                      //                                 style: TextStyle(
                                      //                                     color:
                                      //                                         Colors.white),
                                      //                                 decoration:
                                      //                                     InputDecoration(
                                      //                                   hintText:
                                      //                                       'To',
                                      //                                   hintStyle:
                                      //                                       TextStyle(color: Colors.white70),
                                      //                                   enabledBorder:
                                      //                                       UnderlineInputBorder(
                                      //                                     borderSide:
                                      //                                         BorderSide(color: Colors.white),
                                      //                                   ),
                                      //                                   focusedBorder:
                                      //                                       UnderlineInputBorder(
                                      //                                     borderSide:
                                      //                                         BorderSide(color: Colors.white),
                                      //                                   ),
                                      //                                 ),
                                      //                               ),
                                      //                             ),
                                      //                             IconButton(
                                      //                                 onPressed:
                                      //                                     () {
                                      //                                   FocusScope.of(context)
                                      //                                       .requestFocus(FocusNode());
                                      //                                 },
                                      //                                 icon:
                                      //                                     Icon(
                                      //                                   Icons
                                      //                                       .add,
                                      //                                   color: Colors
                                      //                                       .white,
                                      //                                 ))
                                      //                           ],
                                      //                         );
                                      //                       },
                                      //                     ),
                                      //                   ],
                                      //                 ),
                                      //               ),
                                      //               SizedBox(height: 20),
                                      //               Row(
                                      //                 mainAxisAlignment:
                                      //                     MainAxisAlignment.end,
                                      //                 children: [
                                      //                   TextButton(
                                      //                     style: TextButton
                                      //                         .styleFrom(
                                      //                             foregroundColor:
                                      //                                 Colors
                                      //                                     .white),
                                      //                     onPressed: () {
                                      //                       Navigator.of(
                                      //                               context)
                                      //                           .pop();
                                      //                     },
                                      //                     child: Text(
                                      //                       'Cancel',
                                      //                       style: TextStyle(
                                      //                         color:
                                      //                             Colors.white,
                                      //                         fontWeight:
                                      //                             FontWeight
                                      //                                 .bold,
                                      //                       ),
                                      //                     ),
                                      //                   ),
                                      //                   SizedBox(width: 10),
                                      //                   TextButton(
                                      //                     style: TextButton
                                      //                         .styleFrom(
                                      //                             foregroundColor:
                                      //                                 Colors
                                      //                                     .white),
                                      //                     onPressed: () {
                                      //                       if (_expenseFormKey
                                      //                           .currentState!
                                      //                           .validate()) {
                                      //                         insertUserIncome(); // ← consider renaming if this is about expense
                                      //                       }
                                      //                     },
                                      //                     child: Text(
                                      //                       'Add',
                                      //                       style: TextStyle(
                                      //                         color:
                                      //                             Colors.white,
                                      //                         fontWeight:
                                      //                             FontWeight
                                      //                                 .bold,
                                      //                       ),
                                      //                     ),
                                      //                   ),
                                      //                 ],
                                      //               ),
                                      //             ],
                                      //           ),
                                      //         ),
                                      //       ),
                                      //     );
                                      //   },
                                      // );
                                    }
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return [
                                      PopupMenuItem<String>(
                                        value: 'Add Income',
                                        child: Text('Add Income'),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'Add Expense',
                                        child: Text('Add Expense'),
                                      ),
                                    ];
                                  },
                                  icon: Icon(
                                    Icons.add_circle,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text("₹$balance.00",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ],
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.trending_up_sharp,
                                      color: Colors.green,
                                      // size: 24,
                                    ),
                                    Text(' Income',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        )),
                                  ],
                                ),
                                Row(
                                  // mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.trending_down,
                                        color: Colors.red, size: 20),
                                    Text(' Expense',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        )),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("₹${userAllDetails?['income'] ?? 0}.00",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    )),
                                Text("₹${userAllDetails?['expence'] ?? 0}.00",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ))
                ],
              ),
              // Container(
              //   // height: MediaQuery.of(context).size.height * 0.3,
              //   width: MediaQuery.of(context).size.width * 3,
              //   padding: EdgeInsets.all(20),
              //   decoration: BoxDecoration(
              //     image: DecorationImage(
              //       image: Image.asset('assets/images/background.jpg').image,
              //       fit: BoxFit.cover,
              //     ),
              //     borderRadius: BorderRadius.circular(10),
              //   ),
              //   child: Column(
              //     // mainAxisAlignment: MainAxisAlignment.start,
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       SizedBox(
              //         height: 30,
              //       ),

              //       SizedBox(
              //         height: 20,
              //       ),
              //     ],
              //   ),
              // ),
//Start
              userAllDetailsList.isEmpty
                  ? Center(
                      child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 10.0),
                          child: Column(children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Transaction History',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    )),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Seeall(
                                              userEmail:
                                                  userInfo?['email'] ?? ''),
                                        ),
                                      );
                                    });
                                  },
                                  child: Text(
                                    'See all',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
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
                          Text('Transaction History',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              )),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Seeall(
                                      userEmail: userInfo?['email'] ?? ''),
                                ),
                              );
                            },
                            child: Text(
                              'See all',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

              //User Transaction
              Column(
                children: [
                  for (int i = 0; i < userAllDetailsList.length && i < 3; i++)
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Image.network(
                                'https://img.freepik.com/premium-vector/user-icon-round-grey-icon_1076610-44912.jpg?w=360',
                                height: 50,
                                width: 50,
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (userAllDetailsList[i]['from_user']
                                                ?.toString()
                                                .isNotEmpty ??
                                            false)
                                        ? userAllDetailsList[i]['from_user']
                                            .toString()
                                        : (userAllDetailsList[i]['to_user']
                                                    ?.toString()
                                                    .isNotEmpty ??
                                                false)
                                            ? userAllDetailsList[i]['to_user']
                                                .toString()
                                            : 'Name',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    userAllDetailsList[i]['TIMEDATE'] != null
                                        ? formatTime(
                                            userAllDetailsList[i]['TIMEDATE'])
                                        : '',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            (userAllDetailsList[i]['letest_income']
                                        ?.toString()
                                        .isNotEmpty ??
                                    false)
                                ? '+ ₹${userAllDetailsList[i]['letest_income']}'
                                : (userAllDetailsList[i]['letest_expence']
                                            ?.toString()
                                            .isNotEmpty ??
                                        false)
                                    ? '- ₹${userAllDetailsList[i]['letest_expence']}'
                                    : '0',
                            style: TextStyle(
                              color: (userAllDetailsList[i]['letest_income']
                                          ?.toString()
                                          .isNotEmpty ??
                                      false)
                                  ? Colors.green
                                  : (userAllDetailsList[i]['letest_expence']
                                              ?.toString()
                                              .isNotEmpty ??
                                          false)
                                      ? Colors.red
                                      : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              // SizedBox(
              //   height: 20,
              // ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Send Again',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Seeallsendagain(
                                  userId: userAllDetails?['userId'] ?? ''),
                            ),
                          );
                        },
                        child: Text(
                          'See all',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ))
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                      ),
                      for (var userAllDetails in userAllDetailsList)
                        // if (userAllDetails?['from_user'] == '')
                        Padding(
                          padding: const EdgeInsets.only(right: 15.0),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (userAllDetails['to_user'] == '') {
                                    currentUserName =
                                        userAllDetails['from_user'];
                                  } else if (userAllDetails['from_user'] ==
                                      '') {
                                    currentUserName = userAllDetails['to_user'];
                                  }

                                  print('User name ->>> $currentUserName');

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Usertransaction(
                                        currentUserName: currentUserName,
                                        userId: userAllDetails['userId'],
                                        userEmail: userInfo?['email'],
                                      ), // Explicitly naming the parameter
                                    ),
                                  );
                                  print('Image Data ${userAllDetails}');
                                  // currentUserName = userAllDetails['to_user'];
                                  //User Transaction Details
                                  // showDialog(
                                  //   context: context,
                                  //   builder: (BuildContext context) {
                                  //     return AlertDialog(
                                  //       backgroundColor: Colors
                                  //           .transparent, // Make dialog background transparent
                                  //       contentPadding: EdgeInsets
                                  //           .zero, // Remove default padding
                                  //       content: Container(
                                  //         decoration: BoxDecoration(
                                  //           gradient: LinearGradient(
                                  //             begin: Alignment.topLeft,
                                  //             end: Alignment.bottomRight,
                                  //             colors: [
                                  //               Colors.blue,
                                  //               const Color.fromARGB(
                                  //                   255, 40, 7, 46)
                                  //             ],
                                  //           ),
                                  //           borderRadius:
                                  //               BorderRadius.circular(12),
                                  //         ),
                                  //         child: Padding(
                                  //           padding: const EdgeInsets.all(16.0),
                                  //           child: Column(
                                  //             mainAxisSize: MainAxisSize.min,
                                  //             children: [
                                  //               Text(
                                  //                 'Transaction Details',
                                  //                 style: TextStyle(
                                  //                   fontSize: 20,
                                  //                   fontWeight: FontWeight.bold,
                                  //                   color: Colors.white,
                                  //                 ),
                                  //               ),
                                  //               SizedBox(height: 10),
                                  //               Row(
                                  //                 children: [
                                  //                   Column(
                                  //                     mainAxisAlignment:
                                  //                         MainAxisAlignment
                                  //                             .start,
                                  //                     crossAxisAlignment:
                                  //                         CrossAxisAlignment
                                  //                             .start,
                                  //                     children: [
                                  //                       Column(
                                  //                         crossAxisAlignment:
                                  //                             CrossAxisAlignment
                                  //                                 .start,
                                  //                         children: [
                                  //                           Text(
                                  //                             'To: ${currentUserName}',
                                  //                             style: TextStyle(
                                  //                               color: Colors
                                  //                                   .yellow,
                                  //                               fontSize: 16,
                                  //                               fontWeight:
                                  //                                   FontWeight
                                  //                                       .bold,
                                  //                             ),
                                  //                           ),
                                  //                           for (var userAllDetails
                                  //                               in userAllDetailsList)
                                  //                             if (currentUserName ==
                                  //                                     userAllDetails[
                                  //                                         'to_user'] ||
                                  //                                 currentUserName ==
                                  //                                     userAllDetails[
                                  //                                         'to_user']) // Use currentUser to represent the specific use
                                  //                               Row(
                                  //                                 children: [
                                  //                                   Text(
                                  //                                     'Sent: - ₹${userAllDetails['letest_expence']}',
                                  //                                     style:
                                  //                                         TextStyle(
                                  //                                       color: Colors
                                  //                                           .white,
                                  //                                       fontSize:
                                  //                                           16,
                                  //                                     ),
                                  //                                   ),
                                  //                                   SizedBox(
                                  //                                     width: 10,
                                  //                                   ),
                                  //                                   Text(
                                  //                                     userAllDetails?['TIMEDATE'] !=
                                  //                                             null
                                  //                                         ? formatDateOrTime(
                                  //                                             userAllDetails?['TIMEDATE'])
                                  //                                         : '',
                                  //                                     style:
                                  //                                         TextStyle(
                                  //                                       color: const Color
                                  //                                           .fromARGB(
                                  //                                           255,
                                  //                                           202,
                                  //                                           201,
                                  //                                           201),
                                  //                                       fontSize:
                                  //                                           16,
                                  //                                     ),
                                  //                                   )
                                  //                                 ],
                                  //                               )
                                  //                         ],
                                  //                       ),
                                  //                     ],
                                  //                   ),
                                  //                 ],
                                  //               ),
                                  //               SizedBox(height: 20),
                                  //               Align(
                                  //                 alignment:
                                  //                     Alignment.centerRight,
                                  //                 child: Row(
                                  //                   mainAxisAlignment:
                                  //                       MainAxisAlignment.end,
                                  //                   crossAxisAlignment:
                                  //                       CrossAxisAlignment.end,
                                  //                   children: [
                                  //                     TextButton(
                                  //                       child: Text(
                                  //                         'Close',
                                  //                         style: TextStyle(
                                  //                             color:
                                  //                                 Colors.white),
                                  //                       ),
                                  //                       onPressed: () {
                                  //                         currentUserName = '';
                                  //                         Navigator.of(context)
                                  //                             .pop();
                                  //                       },
                                  //                     ),
                                  //                     TextButton(
                                  //                       child: Text(
                                  //                         'Send Again',
                                  //                         style: TextStyle(
                                  //                             color:
                                  //                                 Colors.white),
                                  //                       ),
                                  //                       onPressed: () {
                                  //                         currentUserName =
                                  //                             userAllDetails?[
                                  //                                 'to_user'];
                                  //                         expence.clear();
                                  //                         Navigator.of(context)
                                  //                             .pop();
                                  //                         showAddExpenseDialog(
                                  //                           context: context,
                                  //                           formKey:
                                  //                               _expenseFormKey,
                                  //                           expenseController:
                                  //                               expence,
                                  //                           toUserController:
                                  //                               toUser,
                                  //                           fetchSuggestion:
                                  //                               fetchSuggestion,
                                  //                           onSubmit: () {
                                  //                             insertUserIncome(); // Or your actual expense saving logic
                                  //                           },
                                  //                         );
                                  //                       },
                                  //                     ),
                                  //                   ],
                                  //                 ),
                                  //               ),
                                  //             ],
                                  //           ),
                                  //         ),
                                  //       ),
                                  //     );
                                  //   },
                                  // );
                                },
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: NetworkImage(
                                    'https://img.freepik.com/premium-vector/user-icon-round-grey-icon_1076610-44912.jpg?w=360',
                                  ),
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                (() {
                                  String userName = '';
                                  if (userAllDetails['from_user']
                                      .toString()
                                      .isNotEmpty) {
                                    userName =
                                        userAllDetails['from_user'].toString();
                                  } else if (userAllDetails['to_user']
                                      .toString()
                                      .isNotEmpty) {
                                    userName =
                                        userAllDetails['to_user'].toString();
                                  } else {
                                    userName = 'Name';
                                  }
                                  return userName.length > 6
                                      ? '${userName.substring(0, 6)}...'
                                      : userName;
                                })(),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
