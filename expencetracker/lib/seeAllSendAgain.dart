import 'dart:convert';

import 'package:expencetracker/impVar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Seeallsendagain extends StatefulWidget {
  final String userId;
  const Seeallsendagain({super.key, required this.userId});

  @override
  State<Seeallsendagain> createState() => _SeeallsendagainState();
}

List<Map<String, dynamic>> userAllDetailsList2 = [];
Map<String, dynamic>? userAllDetails2;

class _SeeallsendagainState extends State<Seeallsendagain> {
  void initState() {
    super.initState();
    print('first id -> ${widget.userId}');
    fetchUserDetails(widget.userId);
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
          userAllDetails2 = userAllDetail;
          userAllDetailsList2 = List<Map<String, dynamic>>.from(responseBody);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Send Again'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              userAllDetailsList2.isEmpty
                  ? Center(
                      child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 10.0),
                          child: Column(children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Text('Transaction History',
                                //     style: TextStyle(
                                //       color: Colors.black,
                                //       fontSize: 20,
                                //       fontWeight: FontWeight.bold,
                                //     )),
                                // TextButton(
                                //   onPressed: () {
                                //     Navigator.push(
                                //       context,
                                //       MaterialPageRoute(
                                //         builder: (context) => Seeall(
                                //             userId: userAllDetails2?['userId']),
                                //       ),
                                //     );
                                //   },
                                //   child: Text(
                                //     'See all',
                                //     style: TextStyle(
                                //       color: Colors.black,
                                //       fontSize: 16,
                                //     ),
                                //   ),
                                // ),
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
                          // Text('Transaction History',
                          //     style: TextStyle(
                          //       color: Colors.black,
                          //       fontSize: 20,
                          //       fontWeight: FontWeight.bold,
                          //     )),
                          // TextButton(
                          //   onPressed: () {
                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (context) => Seeall(
                          //             userId: userAllDetails2?['userId']),
                          //       ),
                          //     );
                          //   },
                          //   child: Text(
                          //     'See all',
                          //     style: TextStyle(
                          //       color: Colors.black,
                          //       fontSize: 16,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),

              //User Transaction
              for (userAllDetails2 in userAllDetailsList2)
                if (userAllDetails2?['from_user'] == '')
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.network(
                                'https://img.freepik.com/premium-vector/user-icon-round-grey-icon_1076610-44912.jpg?w=360',
                                height: 50,
                                width: 50),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userAllDetails2?['to_user'] ?? 'To User',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  userAllDetails2?['TIMEDATE'] != null
                                      ? formatDateOrTime(
                                          userAllDetails2?['TIMEDATE'])
                                      : '',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '- ₹${userAllDetails2?['letest_expence']}',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Text(
                        //   (userAllDetails['letest_income'].isNotEmpty)
                        //       ? '+ ₹${userAllDetails['letest_income']}'
                        //       : ((userAllDetails['letest_expence'].isNotEmpty))
                        //           ? '- ₹${userAllDetails['letest_expence']}'
                        //           : '0',
                        //   style: TextStyle(
                        //     color: (userAllDetails['letest_income'].isNotEmpty)
                        //         ? Colors.green
                        //         : (userAllDetails['letest_expence'].isNotEmpty)
                        //             ? Colors.red
                        //             : Colors.black, // fallback color
                        //     fontSize: 16,
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        // ),
                      ],
                    ),
                  ),

              SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
