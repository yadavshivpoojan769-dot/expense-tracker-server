import 'dart:convert';

import 'package:expencetracker/impVar.dart';
import 'package:expencetracker/mainPage.dart';
import 'package:expencetracker/utils/loading_fallback_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Budget extends StatefulWidget {
  final String userEmail;
  const Budget({super.key, required this.userEmail});

  @override
  State<Budget> createState() => _BudgetState();
}

class _BudgetState extends State<Budget> {
  // final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? userInfo;
  Map<String, dynamic>? budgetTransactions;
  List<Map<String, dynamic>> budgetTransactionList = [];
  List<Map<String, dynamic>> transactionAllDetailsList = [];
  TextEditingController title = TextEditingController();
  TextEditingController amount = TextEditingController();
  TextEditingController date = TextEditingController();
  List<Map<String, TextEditingController>> controllers = [
    {
      'amount': TextEditingController(),
      'to': TextEditingController(),
    }
  ];
  int totalremainingBalance = 0;
  int totalBudgetExpense = 0;
  String? message;
  Color messageColor = Colors.red;
  bool isLoading2 = false;
  bool isError = false;
  bool isLoading = true;

  // bool isSelected = false;

  // final String uid = '';

  DateTime? selectedDate;

  void initState() {
    super.initState();
    print('email aaya -> ${widget.userEmail}');
    loadAllFunction();
  }

  Future<void> loadAllFunction() async {
    setState(() {
      isLoading = true;
    });

    try {
      await fetchUserInfo(widget.userEmail);
      final uid = userInfo?['id'];
      print('Userrriddd = ${uid}');
      await fetchBudgetTransaction((uid).toString());
      print('Budget Transaction details > ${budgetTransactionList}');
      await addTransactionFields();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> totalRemainingBalance(budgetTransactions) async {
    if (budgetTransactions == null) return;

    int totalExpense = 0;
    for (var j in budgetTransactions!['transactionDetails']) {
      totalExpense += int.tryParse(j['amount'].toString()) ?? 0;
    }

    int totalBudget =
        int.tryParse(budgetTransactions!['amount'].toString()) ?? 0;

    int remainingBalance = totalBudget - totalExpense;
    totalremainingBalance = remainingBalance;
    // totalBudgetExpense = totalExpense;
    print("Remaining Balance: ₹$remainingBalance");
    // if (totalremainingBalance > 0) {
    //   // saveTransactions();
    // }
  }

//Add transaction
  List<Map<String, dynamic>> transactionDetails = [];
  Future<void> addTransactionFields() async {
    setState(() {
      controllers.add({
        'amount': TextEditingController(),
        'to': TextEditingController(),
      });
    });
  }

//User information
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
          print('User info in budget -> $userInfo');
        } else {
          print('No user found');
        }
      } else {
        print('Failed to load user info');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  //Fetch LIMITED Budget Transaction
  Future<void> fetchBudgetTransaction(String uid) async {
    try {
      final response = await http.post(
        Uri.parse('${server}showdata/budgetTransaction'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({"uid": uid}),
      );
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody is List && responseBody.isNotEmpty) {
          final budgetTransaction = responseBody[0] as Map<String, dynamic>;
          budgetTransactions = budgetTransaction;
          budgetTransactionList = List<Map<String, dynamic>>.from(responseBody);
          isLoading2 = false;
          setState(() {});
          print('budgetTransactionList-> ${budgetTransactionList}');
          print('budgetTransactions -> ${budgetTransactions}');
        } else {
          print('Failed to fetch budget transaction');
          setState(() {
            isLoading2 = true;
          });
        }
      }
    } catch (err) {
      print('Error fetching budget transaction: $err');
    }
  }

  //Delete LIMITED Budget Transaction
  Future<void> deleteBudgetTransaction(String tid) async {
    try {
      final response = await http.post(
        Uri.parse('${server}showdata/deletebudgetTransaction'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({"id": tid}),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        if (responseBody['success'] == true) {
          print('Deleted successfully');
          setState(() {});
          await fetchBudgetTransaction((userInfo?['id']).toString());
          if (userInfo == null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => MainPage(
                        currentIndex: 2,
                        userEmail: widget.userEmail,
                      )),
            );
          }
        } else {
          print('Failed to delete transaction: ${responseBody['message']}');
        }
      } else {
        print('Server error: ${response.statusCode}');
      }
    } catch (err) {
      print('Error deleting user transaction: $err');
    }
  }

//Insert Budget
  Future<void> insertBudget(
      List<Map<String, dynamic>> finalTransactionDetails) async {
    try {
      final response = await http.post(
        Uri.parse('${server}userdetails/budget/insert'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "title": title.text,
          "amount": amount.text,
          "date": date.text,
          "uid": userInfo?['id'],
          "transactionDetails": finalTransactionDetails,
        }),
      );
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody == 'success') {
          setState(() {});
          await fetchBudgetTransaction((userInfo?['id']).toString());
          print("Budget successfully inserted");
          print('Transaction -> $finalTransactionDetails');
        } else {
          print('Failed to insert budget');
        }
      } else {
        print('Failed to insert budget: ${response.statusCode}');
      }
    } catch (e) {
      print('Error inserting budget: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // to, amount
    // transactionDetails
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.05,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Budget and Balance',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        // fontFamily: 'Times New Roman',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              // Divider(color: Colors.grey),
              Container(
                height: 2,
                color: Colors.grey,
              ),
              SizedBox(
                height: 10,
              ),
              isLoading2
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Recently added',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ],
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Text('No history found',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                      // fontWeight: FontWeight.bold,
                                    )),
                              ],
                            ),
                            SizedBox(
                              height: 20,
                            )
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 15,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text('Recently added',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),
                        ],
                      ),
                    ),

              // SizedBox(height: 20),
              if (isLoading2 == false)
                for (var budgetTransactions in budgetTransactionList)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                print('clicked details $budgetTransactions');
                                totalRemainingBalance(budgetTransactions);

                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color.fromARGB(
                                                  255, 253, 253, 253),
                                              Color.fromARGB(
                                                  255, 190, 189, 190),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        padding: EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Center(
                                              child: Text(
                                                budgetTransactions['title'] ??
                                                    'No title found',
                                                style: TextStyle(
                                                  fontFamily: 'Times New Roman',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 22,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              'Total Budget: ₹${budgetTransactions['amount'] ?? '0.00'}',
                                              style: TextStyle(
                                                fontFamily: 'Times New Roman',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: Color.fromARGB(
                                                    255, 15, 133, 19),
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              'Expenses:',
                                              style: TextStyle(
                                                fontFamily: 'Times New Roman',
                                                fontWeight: FontWeight.bold,
                                                color: Color.fromARGB(
                                                    255, 170, 133, 13),
                                                fontSize: 18,
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            if (budgetTransactions[
                                                    'transactionDetails'] !=
                                                null)
                                              ...budgetTransactions[
                                                      'transactionDetails']
                                                  .map<Widget>((i) {
                                                return Text(
                                                  '₹ ${i['amount']} - ${i['to']}',
                                                  style: TextStyle(
                                                    fontFamily:
                                                        'Times New Roman',
                                                    color: Colors.black,
                                                    fontSize: 18,
                                                  ),
                                                );
                                              }).toList(),
                                            Divider(color: Colors.grey),
                                            Text(
                                              'Remaining Balance: ₹$totalremainingBalance',
                                              style: TextStyle(
                                                fontFamily: 'Times New Roman',
                                                fontWeight: FontWeight.bold,
                                                color: Color.fromARGB(
                                                    255, 170, 133, 13),
                                                fontSize: 18,
                                              ),
                                            ),
                                            SizedBox(height: 20),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 10),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text("Close"),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color.fromARGB(255, 253, 253, 253),
                                      Color.fromARGB(255, 190, 189, 190),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        MediaQuery.of(context).size.width *
                                            0.05,
                                    vertical:
                                        MediaQuery.of(context).size.width *
                                            0.03,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Date: ${budgetTransactions['date'] ?? 'No date found'}',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      Text(
                                        'Title: ${budgetTransactions['title'] ?? 'No title Found'}',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'Times New Roman',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              child: IconButton(
                                onPressed: () {
                                  print("Delete tapped!");
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color.fromARGB(
                                                    255, 253, 253, 253),
                                                Color.fromARGB(
                                                    255, 190, 189, 190),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          padding: EdgeInsets.all(20),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "Confirm Delete",
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              SizedBox(height: 15),
                                              Text(
                                                "Are you sure you want to delete this transaction?",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              SizedBox(height: 20),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(),
                                                    child: Text(
                                                      "No",
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  TextButton(
                                                    onPressed: () {
                                                      // print(
                                                      //     'Mil gaya hai id - ${budgetTransactions['id']}');
                                                      final tid =
                                                          budgetTransactions[
                                                                  'id']
                                                              ?.toString();
                                                      if (tid != null &&
                                                          tid.isNotEmpty) {
                                                        deleteBudgetTransaction(
                                                            tid);
                                                      } else {
                                                        print(
                                                            "User ID is null or empty!");
                                                      }
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: Text(
                                                      "Yes",
                                                      style: TextStyle(
                                                        color: Colors.redAccent,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
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
                                },
                                icon: Icon(Icons.delete, color: Colors.white),
                              ),
                              //   ],
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                      ],
                    ),
                  ),
              LoadingFallbackWidget(
                isLoading: isLoading,
                hasData: userInfo?.isNotEmpty ?? false,
                onReload: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MainPage(
                        currentIndex: 2,
                        userEmail: widget.userEmail,
                      ),
                    ),
                  );
                },
                fallbackMessage: 'No transaction history available',
                child: SizedBox(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: ElevatedButton(
          onPressed: () {
            message = '';

            title.clear();
            amount.clear();
            date.clear();
            controllers = [
              {'amount': TextEditingController(), 'to': TextEditingController()}
            ];
            //Menu
            showDialog(
              context: context,
              builder: (BuildContext context) {
                final _formKey = GlobalKey<FormState>();

                // Define these here to maintain inside dialog's state
                List<Map<String, TextEditingController>> controllers = [
                  {
                    'amount': TextEditingController(),
                    'to': TextEditingController()
                  }
                ];
                List<Map<String, dynamic>> transactionDetails = [];

                return StatefulBuilder(
                  builder: (context, setState) {
                    void addTransactionFields() {
                      setState(() {
                        controllers.add({
                          'amount': TextEditingController(),
                          'to': TextEditingController(),
                        });
                      });
                    }

                    void saveTransactions() {
                      if (_formKey.currentState!.validate()) {
                        transactionDetails.clear();
                        for (var pair in controllers) {
                          transactionDetails.add({
                            'amount': pair['amount']!.text.trim(),
                            'to': pair['to']!.text.trim(),
                          });
                        }

                        insertBudget(transactionDetails);
                        Navigator.of(context).pop();
                      }
                    }

                    return Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromARGB(255, 253, 253, 253),
                              Color.fromARGB(255, 190, 189, 190),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: EdgeInsets.all(16),
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Form(
                          key: _formKey,
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Add your budget',
                                    style: TextStyle(
                                      fontFamily: 'Times New Roman',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  TextFormField(
                                    controller: title,
                                    decoration: InputDecoration(
                                      labelText: 'Title',
                                      labelStyle: TextStyle(
                                          fontFamily: 'Times New Roman',
                                          color: Colors.black),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.grey),
                                      ),
                                      errorBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.redAccent),
                                      ),
                                      errorStyle: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 14,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Times New Roman',
                                      color: Colors.black,
                                    ),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Enter title'
                                            : null,
                                  ),
                                  SizedBox(height: 10),
                                  TextFormField(
                                    controller: amount,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Total Amount',
                                      labelStyle: TextStyle(
                                          fontFamily: 'Times New Roman',
                                          color: Colors.black),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.grey),
                                      ),
                                      errorBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.redAccent),
                                      ),
                                      errorStyle: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 14,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Times New Roman',
                                      color: Colors.black,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter amount';
                                      }
                                      final numValue = double.tryParse(value);
                                      if (numValue == null || numValue <= 0) {
                                        return 'Amount should be greater than 0';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 10),
                                  TextFormField(
                                    controller: date,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      labelText: 'Date',
                                      labelStyle: TextStyle(
                                          fontFamily: 'Times New Roman',
                                          color: Colors.black),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.grey),
                                      ),
                                      errorBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.redAccent),
                                      ),
                                      errorStyle: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 14,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Times New Roman',
                                      color: Colors.black,
                                    ),
                                    onTap: () async {
                                      FocusScope.of(context).unfocus();
                                      DateTime? pickedDate =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (pickedDate != null) {
                                        setState(() {
                                          selectedDate = pickedDate;
                                          date.text = "${pickedDate.toLocal()}"
                                              .split(' ')[0];
                                        });
                                      }
                                    },
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Select date'
                                            : null,
                                  ),
                                  SizedBox(height: 20),
                                  ...List.generate(controllers.length, (index) {
                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Transaction ${index + 1}:',
                                          style: TextStyle(
                                            color: Color.fromARGB(
                                                255, 128, 128, 127),
                                            fontSize: 18,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: controllers[index]
                                                    ['amount'],
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText: 'Enter Amount',
                                                  labelStyle: TextStyle(
                                                    fontFamily:
                                                        'Times New Roman',
                                                    color: Colors.black,
                                                  ),
                                                  enabledBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.grey),
                                                  ),
                                                  errorBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color:
                                                            Colors.redAccent),
                                                  ),
                                                  errorStyle: TextStyle(
                                                    color: Colors.redAccent,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                style: TextStyle(
                                                  fontFamily: 'Times New Roman',
                                                  color: Colors.black,
                                                ),
                                                validator: (value) =>
                                                    value == null ||
                                                            value.isEmpty
                                                        ? 'Enter amount'
                                                        : null,
                                              ),
                                            ),
                                            SizedBox(
                                                width:
                                                    16), // Space between the fields
                                            Expanded(
                                              child: TextFormField(
                                                controller: controllers[index]
                                                    ['to'],
                                                keyboardType:
                                                    TextInputType.text,
                                                decoration: InputDecoration(
                                                  labelText: 'To',
                                                  labelStyle: TextStyle(
                                                    fontFamily:
                                                        'Times New Roman',
                                                    color: Colors.black,
                                                  ),
                                                  enabledBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.grey),
                                                  ),
                                                  errorBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color:
                                                            Colors.redAccent),
                                                  ),
                                                  errorStyle: TextStyle(
                                                    color: Colors.redAccent,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                style: TextStyle(
                                                  fontFamily: 'Times New Roman',
                                                  color: Colors.black,
                                                ),
                                                validator: (value) =>
                                                    value == null ||
                                                            value.isEmpty
                                                        ? 'Enter recipient'
                                                        : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                      ],
                                    );
                                  }),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      IconButton(
                                        onPressed: addTransactionFields,
                                        icon: Icon(Icons.add_circle_rounded,
                                            color: Colors.black),
                                        tooltip: 'Add another transaction',
                                      ),
                                      controllers.length > 1
                                          ? IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  if (controllers.length > 1) {
                                                    controllers.last['amount']
                                                        ?.dispose();
                                                    controllers.last['to']
                                                        ?.dispose();
                                                    controllers.removeLast();
                                                  }
                                                });
                                              },
                                              icon: Icon(Icons.cancel,
                                                  color: Colors.redAccent),
                                              tooltip:
                                                  'Remove last transaction',
                                            )
                                          : SizedBox.shrink(),

                                      // Spacer(),
                                    ],
                                  ),
                                  if (message != null)
                                    Padding(
                                      padding: EdgeInsets.only(top: 1),
                                      child: Text(
                                        '$message',
                                        style: TextStyle(color: messageColor),
                                      ),
                                    ),
                                  // SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: Text('Close'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                      ),
                                      SizedBox(width: 20),
                                      ElevatedButton(
                                        onPressed: () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            transactionDetails.clear();
                                            for (var pair in controllers) {
                                              transactionDetails.add({
                                                'amount':
                                                    pair['amount']!.text.trim(),
                                                'to': pair['to']!.text.trim(),
                                              });
                                            }

                                            int totalExpense = 0;
                                            for (var tx in transactionDetails) {
                                              totalExpense +=
                                                  int.tryParse(tx['amount']) ??
                                                      0;
                                            }

                                            int totalBudget =
                                                int.tryParse(amount.text) ?? 0;
                                            int remainingBalance =
                                                totalBudget - totalExpense;

                                            if (remainingBalance >= 0) {
                                              insertBudget(transactionDetails);
                                              Navigator.of(context).pop();
                                            } else {
                                              setState(() {
                                                message =
                                                    'You are exceeding your balance limit.';
                                                messageColor = Colors.red;
                                              });
                                            }
                                          }
                                        },
                                        child: Text('Add'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 106, 107, 107),
            foregroundColor: Colors.white,
            elevation: 5,
            padding: EdgeInsets.all(19),
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
