import 'dart:convert';

import 'package:expencetracker/impVar.dart';
import 'package:expencetracker/mainPage.dart';
import 'package:expencetracker/seeAll.dart';
import 'package:expencetracker/shop.dart';
import 'package:expencetracker/userTransaction.dart';
import 'package:expencetracker/utils/loading_fallback_widget.dart';
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

bool isTracking = true;
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
  bool isLoading = true;

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
    setState(() {
      isLoading = true;
    });

    try {
      await fetchUserInfo(widget.userEmail);
      final useridd = userInfo?["id"];
      print(' useridd -> ${useridd}');
      await limitedUserDetails('$useridd');
      // await fetchUserDetails('$useridd');
      await totalBalance();
      await fatchTransaction();
      // print('Transaction name is' + userAllDetails?['from_user'] + 'MMMMM');
      // print('Transaction name is' + userAllDetails?['to_user'] + 'YYYYY');
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
    final allNames = <String>{}; // Use a Set to avoid duplicates

    if (query.isEmpty) {
      return []; // Return an empty list if no input is provided
    }

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

    final filtered = allNames
        .where((name) => name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    // Alphabatically sort
    filtered.sort();

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

  Future<void> limitedUserDetails(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('${server}showdata/limiteduserDetails'),
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
        Uri.parse('${server}userdetails/insert'),
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
    String userName = 'Name'; // Default name

    if (userAllDetails['from_user'] != null &&
        userAllDetails['from_user'].toString().isNotEmpty) {
      userName = userAllDetails['from_user'];
    } else if (userAllDetails['to_user'] != null &&
        userAllDetails['to_user'].toString().isNotEmpty) {
      userName = userAllDetails['to_user'];
    }

    String? userImage = userAllDetails['image'];
    String firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : "U";

    // ✅ income / expense check
    String amountText = '0';
    Color amountColor = Colors.black;

    if (userAllDetails['letest_income'] != null &&
        userAllDetails['letest_income'].toString().isNotEmpty) {
      amountText = '+ ₹${userAllDetails['letest_income']}';
      amountColor = Colors.green;
    } else if (userAllDetails['letest_expence'] != null &&
        userAllDetails['letest_expence'].toString().isNotEmpty) {
      amountText = '- ₹${userAllDetails['letest_expence']}';
      amountColor = Colors.red;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
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
        ),
        Text(
          amountText,
          style: TextStyle(
            color: amountColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildRecentuser(
    BuildContext context,
    Map<String, dynamic> userAllDetails,
    Set<String> displayedNames,
    Map<String, dynamic>? userInfo,
  ) {
    String userName = 'Name'; // Default name

    if (userAllDetails['from_user'] != null &&
        userAllDetails['from_user'].toString().isNotEmpty) {
      userName = userAllDetails['from_user'].toString();
    } else if (userAllDetails['to_user'] != null &&
        userAllDetails['to_user'].toString().isNotEmpty) {
      userName = userAllDetails['to_user'].toString();
    }

    // Skip if user already displayed
    if (displayedNames.contains(userName)) {
      return const SizedBox.shrink(); // no padding -> no space
    }
    displayedNames.add(userName);

    String displayName =
        userName.length > 6 ? '${userName.substring(0, 6)}...' : userName;
    String firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : "U";

    return Padding(
      padding: const EdgeInsets.only(right: 15.0), // moved inside
      child: GestureDetector(
        onTap: () {
          String currentUserName = userName;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Usertransaction(
                currentUserName: currentUserName,
                userId: userAllDetails['userId'],
                userEmail: userInfo?['email'],
              ),
            ),
          );

          print('Navigating to user -> $currentUserName');
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const SizedBox(height: 8),
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
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
                          suggestionsCallback: (query) {
                            return fetchSuggestion(
                                query); // Uses the modified fetchSuggestion method
                          },
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
                          emptyBuilder: (context) =>
                              SizedBox.shrink(), // Prevents showing empty state
                          builder: (context, controller, focusNode) {
                            return Row(
                              children: [
                                Expanded(
                                  child: TextField(
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
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    FocusScope.of(context).unfocus();
                                  },
                                  icon: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                )
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
                          suggestionsCallback: (query) {
                            return fetchSuggestion(
                                query); // Same fetchSuggestion method for both fields
                          },
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
                          emptyBuilder: (context) =>
                              SizedBox.shrink(), // Prevent empty state display
                          builder: (context, controller, focusNode) {
                            return Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    cursorColor: Colors.white,
                                    style: TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'To', // Label for "To" field
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
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    FocusScope.of(context).unfocus();
                                  },
                                  icon: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                )
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
                    ),
                  ),
                  //Container 2
                  Positioned(
                    top: -MediaQuery.of(context).size.height *
                        0.25, // instead of -200
                    left: -MediaQuery.of(context).size.width *
                        0.12, // instead of -50
                    child: Container(
                      width: 500,
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
                            // LoadingFallbackWidget(
                            //   isLoading: isLoading,
                            //   hasData: userInfo?['name'] != null,
                            //   onReload: () {
                            //     Navigator.pushReplacement(
                            //       context,
                            //       MaterialPageRoute(
                            //         builder: (context) => MainPage(
                            //           currentIndex: 0,
                            //           userEmail: widget.userEmail,
                            //         ),
                            //       ),
                            //     );
                            //   },
                            //   fallbackMessage: 'User information not available',
                            //   child: Text(
                            //     '${userInfo?['name']}',
                            //     style: TextStyle(
                            //       color: Colors.yellow,
                            //       fontSize: 20,
                            //       fontWeight: FontWeight.bold,
                            //     ),
                            //   ),
                            // ),
                            Text(
                              '${userInfo?['name'] ?? ''}',
                              style: TextStyle(
                                color: Colors.yellow,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
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
                                          ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                elevation: 0,
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),

                                              //Sttttttttt
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(
                                                    12), // ripple effect ko circle banane ke liye
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => Shop(
                                                          userEmail: userInfo?[
                                                                  'email'] ??
                                                              ''),
                                                    ),
                                                  );
                                                },
                                                child: Ink(
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        Color.fromARGB(
                                                            255, 253, 253, 253),
                                                        Color.fromARGB(
                                                            255, 190, 189, 190),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                        color: Colors.black12,
                                                        blurRadius: 4,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.05,
                                                      vertical:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.03,
                                                    ),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const CircleAvatar(
                                                          radius: 25,
                                                          backgroundImage:
                                                              AssetImage(
                                                                  'assets/images/etshop.png'),
                                                        ),
                                                        const SizedBox(
                                                            width: 10),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: const [
                                                              Text(
                                                                '🎉 New Update!',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .black87,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 5),
                                                              Text(
                                                                'Ab ghar baithe shopping karein hamare naye update ke sath 🛍️',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .black54,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              )),
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
              //Start
              LoadingFallbackWidget(
                  isLoading: isLoading,
                  hasData: userAllDetailsList.isNotEmpty,
                  onReload: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MainPage(
                          currentIndex: 0,
                          userEmail: widget.userEmail,
                        ),
                      ),
                    );
                  },
                  fallbackMessage: 'No transaction history available',
                  child: Column(
                    children: [
                      Padding(
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
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Seeall(
                                        userEmail: userInfo?['email'] ?? ''),
                                  ),
                                );
                                // If we get back a result indicating changes were made, refresh the data
                                if (result == true) {
                                  await loadAllfunctions();
                                }
                                // If result is false, no changes were made, so no refresh needed
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
                          for (int i = 0;
                              i < userAllDetailsList.length && i < 3;
                              i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 10.0),
                              child: buildUserProfile(userAllDetailsList[i]),
                            ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Users',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(width: 20),
                              Builder(
                                builder: (context) {
                                  Set<String> displayedNames = {};
                                  return Row(
                                    children: [
                                      for (var userAllDetails
                                          in userAllDetailsList)
                                        buildRecentuser(
                                          context,
                                          userAllDetails,
                                          displayedNames,
                                          userInfo,
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  )),
              // Transaction History Header
            ],
          ),
        ),
      ),
    );
  }
}
