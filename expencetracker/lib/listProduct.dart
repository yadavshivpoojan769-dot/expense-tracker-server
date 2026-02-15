import 'dart:convert';

import 'package:expencetracker/impVar.dart';
import 'package:expencetracker/mainPage.dart';
import 'package:expencetracker/utils/loading_fallback_widget.dart';
import 'package:expencetracker/viewProducts.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Listproduct extends StatefulWidget {
  final String userEmail;
  const Listproduct({super.key, required this.userEmail});

  @override
  State<Listproduct> createState() => _ListproductState();
}

class _ListproductState extends State<Listproduct> {
  TextEditingController title = TextEditingController();
  List<Map<String, TextEditingController>> controllers = [
    {'productName': TextEditingController()}
  ];
  bool isLoading2 = false;
  bool isLoading = true;

  Map<String, dynamic>? userInfo;
  Map<String, dynamic>? allProducts;
  List<Map<String, dynamic>> allproductList = [];

  @override
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
      // print('Userrriddd = ${uid}');
      await fetchProducts((uid).toString());
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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

  Future<void> fetchProducts(String uid) async {
    try {
      final response = await http.post(
        Uri.parse('${server}showdata/allProducts'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({"uid": uid}),
      );
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody is List && responseBody.isNotEmpty) {
          final products = responseBody[0] as Map<String, dynamic>;
          allProducts = products;
          allproductList = List<Map<String, dynamic>>.from(responseBody);
          isLoading2 = false;
          setState(() {});
          print('Products >>  $allproductList');
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
  Future<void> deleteProducts(String tid) async {
    try {
      final response = await http.post(
        Uri.parse('${server}showdata/deleteProducts'),
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
          await fetchProducts((userInfo?['id']).toString());
          if (userInfo == null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => MainPage(
                        currentIndex: 3,
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

  Future<void> insertProducts(
      List<Map<String, dynamic>> finalProductDetails) async {
    try {
      final response = await http.post(
        Uri.parse('${server}userdetails/products/insert'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "title": title.text,
          "uid": userInfo?['id'],
          "productName": finalProductDetails,
        }),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body == 'success') {
          print("Product successfully inserted");
          print("Payload: $finalProductDetails");
          setState(() {});
          await fetchProducts((userInfo?['id']).toString());
          Navigator.of(context).pop();
        } else {
          print("Insert failed: Response not success");
        }
      } else {
        print("Failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error inserting products: $e");
    }
  }

  void openAddProductDialog() {
    final _formKey = GlobalKey<FormState>();
    List<Map<String, TextEditingController>> localControllers = [
      {'productName': TextEditingController()}
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void addProductField() {
              setState(() {
                localControllers.add({'productName': TextEditingController()});
              });
            }

            void removeProductField() {
              if (localControllers.length > 1) {
                setState(() {
                  localControllers.last['productName']?.dispose();
                  localControllers.removeLast();
                });
              }
            }

            void saveProducts() {
              if (_formKey.currentState!.validate()) {
                final productList = localControllers
                    .map((ctrl) => {
                          'productName': ctrl['productName']!.text.trim(),
                        })
                    .toList();
                insertProducts(productList);
              }
            }

// How to set
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              backgroundColor: Color.fromARGB(
                  255, 253, 253, 253), // very light grey bg for dialog
              child: Container(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Add Product',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: title,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            labelStyle: TextStyle(
                              color: Color.fromARGB(255, 105, 105,
                                  105), // blueGrey replaced with medium grey
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: Icon(Icons.title,
                                color: Color.fromARGB(
                                    255, 128, 128, 128)), // grey icon
                            filled: true,
                            fillColor: Color.fromARGB(255, 253, 253,
                                253), // very light grey background
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 20.0),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 190, 189,
                                      190)), // medium grey border
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 120, 120, 120),
                                  width: 2.0), // darker grey on focus
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(
                                  color: Colors.redAccent, width: 2.0),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide:
                                  BorderSide(color: Colors.red, width: 2.0),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter title'
                              : null,
                        ),
                        SizedBox(height: 10),
                        ...List.generate(localControllers.length, (index) {
                          return Column(
                            children: [
                              TextFormField(
                                controller: localControllers[index]
                                    ['productName'],
                                decoration: InputDecoration(
                                  labelText: 'Product ${index + 1}',
                                  labelStyle: TextStyle(
                                    color: Color.fromARGB(255, 130, 130,
                                        130), // a medium grey for label text
                                    fontWeight: FontWeight.w600,
                                  ),
                                  prefixIcon: Icon(Icons.shopping_bag_outlined,
                                      color: Color.fromARGB(
                                          255, 120, 120, 120)), // grey icon
                                  filled: true,
                                  fillColor: Color.fromARGB(255, 253, 253,
                                      253), // very light grey background
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 16.0, horizontal: 20.0),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: BorderSide(
                                        color: Color.fromARGB(255, 190, 189,
                                            190)), // medium grey border
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: BorderSide(
                                        color:
                                            Color.fromARGB(255, 120, 120, 120),
                                        width: 2.0), // darker grey on focus
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: BorderSide(
                                        color: Colors.redAccent, width: 2.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: BorderSide(
                                        color: Colors.red, width: 2.0),
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Enter product name'
                                        : null,
                              ),
                              SizedBox(height: 10),
                            ],
                          );
                        }),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: addProductField,
                              icon: Icon(Icons.add,
                                  color: Color.fromARGB(
                                      255, 120, 120, 120)), // grey icon
                              label: Text(
                                "Add Product",
                                style: TextStyle(
                                  color: Color.fromARGB(
                                      255, 105, 105, 105), // medium grey text
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Color.fromARGB(
                                    255, 253, 253, 253), // very light grey bg
                                padding: EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  side: BorderSide(
                                      color: Color.fromARGB(255, 190, 189,
                                          190)), // medium grey border
                                ),
                              ),
                            ),
                            if (localControllers.length > 1)
                              TextButton.icon(
                                onPressed: removeProductField,
                                icon: Icon(Icons.remove_circle_outline,
                                    color: Color.fromARGB(
                                        255, 120, 120, 120)), // grey icon
                                label: Text(
                                  "Remove",
                                  style: TextStyle(
                                    color: Color.fromARGB(
                                        255, 105, 105, 105), // medium grey text
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: Color.fromARGB(
                                      255, 253, 253, 253), // very light grey bg
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    side: BorderSide(
                                        color: Color.fromARGB(255, 190, 189,
                                            190)), // medium grey border
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                // backgroundColor:
                                //     Color.fromARGB(255, 92, 92, 92),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 20),
                                elevation:
                                    0, // flat style, change if you want shadow
                              ),
                              child: Text(
                                "Close",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            TextButton(
                              onPressed: saveProducts,
                              style: ElevatedButton.styleFrom(
                                // backgroundColor: Colors.green,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 20),
                                elevation: 0,
                              ),
                              child: Text(
                                "Save",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Add Your Producs",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              if (isLoading2 == false)
                for (var allProducts in allproductList)
                  //Buttons
                  Padding(
                    padding: EdgeInsets.all(9.0),
                    child: Column(
                      children: [
                        Stack(alignment: Alignment.topRight, children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Viewproducts(
                                    userId: allProducts['uid'] ?? '',
                                    id: allProducts['id'] ?? '',
                                  ),
                                ),
                              );
                              //Start
                              // showDialog(
                              //   context: context,
                              //   builder: (BuildContext context) {
                              //     return Dialog(
                              //       shape: RoundedRectangleBorder(
                              //         borderRadius: BorderRadius.circular(15),
                              //       ),
                              //       child: Container(
                              //         decoration: BoxDecoration(
                              //           gradient: LinearGradient(
                              //             begin: Alignment.topLeft,
                              //             end: Alignment.bottomRight,
                              //             colors: [
                              //               Color.fromARGB(255, 253, 253, 253),
                              //               Color.fromARGB(255, 190, 189, 190),
                              //             ],
                              //           ),
                              //           borderRadius: BorderRadius.circular(15),
                              //         ),
                              //         padding: EdgeInsets.all(20),
                              //         child: Column(
                              //           mainAxisSize: MainAxisSize.min,
                              //           crossAxisAlignment:
                              //               CrossAxisAlignment.start,
                              //           children: [
                              //             Center(
                              //               child: Text(
                              //                 allProducts['title'] ??
                              //                     'No title found',
                              //                 style: TextStyle(
                              //                   fontFamily: 'Times New Roman',
                              //                   fontWeight: FontWeight.bold,
                              //                   fontSize: 22,
                              //                   color: Colors.black,
                              //                 ),
                              //               ),
                              //             ),
                              //             SizedBox(height: 10),
                              //             SizedBox(height: 10),
                              //             Row(
                              //               mainAxisAlignment:
                              //                   MainAxisAlignment.spaceBetween,
                              //               children: [
                              //                 Text(
                              //                   'Listed Items:',
                              //                   style: TextStyle(
                              //                     fontFamily: 'Times New Roman',
                              //                     fontWeight: FontWeight.bold,
                              //                     color: Color.fromARGB(
                              //                         255, 248, 190, 0),
                              //                     fontSize: 18,
                              //                   ),
                              //                 ),
                              //                 IconButton(
                              //                   onPressed: () {
                              //                     if (allProducts[
                              //                             'productName'] !=
                              //                         null) {
                              //                       final products =
                              //                           allProducts[
                              //                                   'productName']
                              //                               as List<dynamic>;

                              //                       // Build the string
                              //                       final copiedText = products
                              //                           .asMap()
                              //                           .entries
                              //                           .map((entry) {
                              //                         int index = entry.key;
                              //                         var product = entry.value;
                              //                         return '${index + 1}. ${product['productName']}';
                              //                       }).join('\n');

                              //                       Clipboard.setData(
                              //                           ClipboardData(
                              //                               text: copiedText));

                              //                       // Optional: show a message
                              //                       ScaffoldMessenger.of(
                              //                               context)
                              //                           .showSnackBar(
                              //                         SnackBar(
                              //                             content: Text(
                              //                                 'Product names copied to clipboard')),
                              //                       );
                              //                     }
                              //                   },
                              //                   icon: Icon(Icons.copy),
                              //                   tooltip: 'Copy products',
                              //                 ),
                              //               ],
                              //             ),
                              //             SizedBox(height: 10),
                              //             if (allProducts['productName'] !=
                              //                 null)
                              //               ...allProducts['productName']
                              //                   .asMap()
                              //                   .entries
                              //                   .map<Widget>((entry) {
                              //                 int index = entry.key;
                              //                 var product = entry.value;
                              //                 return Text(
                              //                   '${index + 1}. ${product['productName']}',
                              //                   style: TextStyle(
                              //                     fontFamily: 'Times New Roman',
                              //                     color: Colors.black,
                              //                     fontSize: 18,
                              //                   ),
                              //                 );
                              //               }).toList(),
                              //             Divider(color: Colors.black),
                              //             SizedBox(height: 20),
                              //             Align(
                              //               alignment: Alignment.centerRight,
                              //               child: ElevatedButton(
                              //                 style: ElevatedButton.styleFrom(
                              //                   backgroundColor: Color.fromARGB(
                              //                       255, 92, 92, 92),
                              //                   foregroundColor: Colors.white,
                              //                   padding: EdgeInsets.symmetric(
                              //                       horizontal: 20,
                              //                       vertical: 10),
                              //                   shape: RoundedRectangleBorder(
                              //                     borderRadius:
                              //                         BorderRadius.circular(8),
                              //                   ),
                              //                 ),
                              //                 onPressed: () {
                              //                   Navigator.of(context).pop();
                              //                 },
                              //                 child: Text("Close"),
                              //               ),
                              //             ),
                              //           ],
                              //         ),
                              //       ),
                              //     );
                              //   },
                              // );
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
                                      MediaQuery.of(context).size.width * 0.05,
                                  vertical:
                                      MediaQuery.of(context).size.width * 0.03,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      allProducts['TIMEDATE'] != null
                                          ? formatDateOrTime(
                                              allProducts['TIMEDATE'])
                                          : '',
                                      style: TextStyle(
                                        color: Colors.black,
                                        // fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${allProducts['title']}',
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
                                              "Are you sure you want to delete this product list?",
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
                                                    print(
                                                        'Mil gaya hai id - ${allProducts['id']}');
                                                    final tid =
                                                        allProducts['id']
                                                            ?.toString();
                                                    if (tid != null &&
                                                        tid.isNotEmpty) {
                                                      deleteProducts(tid);
                                                    } else {
                                                      print(
                                                          "User ID is null or empty!");
                                                    }
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text(
                                                    "Yes",
                                                    style: TextStyle(
                                                      color: Colors.black,
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
                        ])
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
                        currentIndex: 3,
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
      floatingActionButton: SizedBox(
        width: 60, // Default is 56, so increase as needed
        height: 60,
        child: FloatingActionButton(
          onPressed: () {
            title.clear();
            openAddProductDialog();
          },
          backgroundColor: const Color.fromARGB(255, 106, 107, 107),
          shape: CircleBorder(),
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 30, // Optional: Increase icon size to match
          ),
        ),
      ),
    );
  }
}
