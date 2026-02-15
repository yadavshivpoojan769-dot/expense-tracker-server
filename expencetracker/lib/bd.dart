import 'dart:convert';

import 'package:expencetracker/impVar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Bd extends StatefulWidget {
  final String userEmail;
  const Bd({super.key, required this.userEmail});

  @override
  State<Bd> createState() => _BdState();
}

class _BdState extends State<Bd> {
  Map<String, dynamic>? userInfo;
  TextEditingController title = TextEditingController();
  TextEditingController amount = TextEditingController();
  TextEditingController date = TextEditingController();

  List<Map<String, dynamic>> transactionDetails = [];
  TextEditingController to = TextEditingController();
  TextEditingController enteredAmount = TextEditingController();
  // List<TextEditingController> toControllers = [];
  // List<TextEditingController> amountControllers = [];

  void initState() {
    super.initState();
    fetchUserInfo(widget.userEmail);
    // loadUserInfo();
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

//Insert Budget
  Future<void> insertBudget() async {
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
          "transactionDetails": transactionDetails,
        }),
      );
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody == 'success') {
          print("User details mil gya hai");
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

  void addTransaction() {
    // Get the values from the text controllers
    String recipient = to.text;
    String amount = enteredAmount.text;

    // Create a map to store these values
    Map<String, dynamic> transaction = {
      'to': recipient,
      'amount': amount,
    };

    // Add the transaction to the transactionDetails list
    transactionDetails.add(transaction);

    // Optionally, print the transaction details to verify
    print(transactionDetails);
  }

  @override
  Widget build(BuildContext context) {
    // to, amount
    // transactionDetails
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.05,
              ),
              Text(
                'Budget and Balance',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Times New Roman',
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 15,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      userInfo?['name'] ?? 'Hello Mukul',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Times New Roman',
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    //Grocery Items
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              title: Text(
                                'Grocery Items',
                                style: TextStyle(
                                  fontFamily: 'Times New Roman',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Budget: ₹10,000',
                                    style: TextStyle(
                                      fontFamily: 'Times New Roman',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    'Expenses:',
                                    style: TextStyle(
                                        fontFamily: 'Times New Roman',
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text('₹200 - Rice',
                                      style: TextStyle(
                                          fontFamily: 'Times New Roman')),
                                  Text('₹1500 - Fruits',
                                      style: TextStyle(
                                          fontFamily: 'Times New Roman')),
                                  Text('₹2500 - Personal care items',
                                      style: TextStyle(
                                          fontFamily: 'Times New Roman')),
                                  Divider(),
                                  Text(
                                    'Remaining Balance: ₹5,800',
                                    style: TextStyle(
                                      fontFamily: 'Times New Roman',
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text("Close")),
                              ],
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 44, 207, 248),
                        foregroundColor: Colors.white,
                        elevation: 5,
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                          vertical: MediaQuery.of(context).size.width * 0.03,
                        ),
                        textStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [Text('Date: 29/07/2025')],
                          ),
                          Text(
                            'Title: Grocery Items',
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Times New Roman',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    //Room Rent
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 44, 207, 248),
                        foregroundColor: Colors.white,
                        elevation: 5,
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                          vertical: MediaQuery.of(context).size.width * 0.03,
                        ),
                        textStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [Text('Date: 01/08/2025')],
                          ),
                          Text(
                            'Title: Room Rent',
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Times New Roman',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    //EMI
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 44, 207, 248),
                        foregroundColor: Colors.white,
                        elevation: 5,
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                          vertical: MediaQuery.of(context).size.width * 0.03,
                        ),
                        textStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [Text('Date: 29/07/2025')],
                          ),
                          Text(
                            'Title: EMI',
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Times New Roman',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: ElevatedButton(
          onPressed: () {
            //Menu
            showDialog(
              context: context,
              builder: (BuildContext context) {
                final _formKey = GlobalKey<FormState>();
                title.clear();
                amount.clear();
                date.clear();
                transactionDetails.clear();
                transactionDetails.length = 1;
                return StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      title: Text(
                        'Add Expense',
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: SingleChildScrollView(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Title
                                TextFormField(
                                  controller: title,
                                  decoration: InputDecoration(
                                    labelText: 'Title',
                                    labelStyle: TextStyle(
                                        fontFamily: 'Times New Roman'),
                                  ),
                                  style:
                                      TextStyle(fontFamily: 'Times New Roman'),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a title';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 10),
                                // Amount
                                TextFormField(
                                  controller: amount,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Enter the Amount to Spend',
                                    labelStyle: TextStyle(
                                        fontFamily: 'Times New Roman'),
                                  ),
                                  style:
                                      TextStyle(fontFamily: 'Times New Roman'),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter amount';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 10),

                                // Date
                                TextFormField(
                                  controller: date,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Date',
                                    labelStyle: TextStyle(
                                        fontFamily: 'Times New Roman'),
                                  ),
                                  style:
                                      TextStyle(fontFamily: 'Times New Roman'),
                                  onTap: () async {
                                    FocusScope.of(context)
                                        .requestFocus(FocusNode());
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (pickedDate != null) {
                                      date.text =
                                          "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Select date';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 20),

                                // Dynamic Transaction Fields
                                Text(
                                  'Transaction: ${transactionDetails.length}',
                                  style:
                                      TextStyle(fontFamily: 'Times New Roman'),
                                ),
                                SizedBox(height: 10),

                                Column(
                                  children: List.generate(
                                      transactionDetails.length, (index) {
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: enteredAmount,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText: 'Enter Amount',
                                                labelStyle: TextStyle(
                                                    fontFamily:
                                                        'Times New Roman'),
                                              ),
                                              style: TextStyle(
                                                  fontFamily:
                                                      'Times New Roman'),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Enter amount';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: TextFormField(
                                              controller: to,
                                              decoration: InputDecoration(
                                                labelText: 'To',
                                                labelStyle: TextStyle(
                                                    fontFamily:
                                                        'Times New Roman'),
                                              ),
                                              style: TextStyle(
                                                  fontFamily:
                                                      'Times New Roman'),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Enter recipient';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          if (index ==
                                              transactionDetails.length - 1)
                                            IconButton(
                                              onPressed: () {},
                                              icon: Icon(Icons.add),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              insertBudget();
                              addTransaction();
                              print(
                                  'Transaction details ${transactionDetails}');
                              Navigator.of(context).pop();
                              for (int i = 0;
                                  i < transactionDetails.length;
                                  i++) {
                                print('Sari Transactions ${i + 1}: '
                                    'Amount - ${transactionDetails[i]}, '
                                    'To - ${transactionDetails[i]}');
                              }
                            }
                          },
                          child: Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Close'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 44, 207, 248),
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
          child: Icon(Icons.add_circle_outline_sharp),
        ),
      ),
    );
  }
}
