import 'dart:convert';

import 'package:expencetracker/impVar.dart';
import 'package:expencetracker/mainPage.dart';
import 'package:expencetracker/userTransaction.dart';
import 'package:expencetracker/utils/loading_fallback_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Seeall extends StatefulWidget {
  final String userEmail;
  const Seeall({super.key, required this.userEmail});

  @override
  State<Seeall> createState() => _SeeallState();
}

List<Map<String, dynamic>> userAllDetailsList2 = [];
Map<String, dynamic>? userAllDetails2;

class _SeeallState extends State<Seeall> {
  bool isSelectionMode = false;
  Set<int> selectedIndices = {};
  bool hasChanges = false;
  bool isLoading = true;

  void initState() {
    super.initState();
    loadAllFunction();
  }

  Future<void> loadAllFunction() async {
    setState(() {
      isLoading = true;
    });

    try {
      await fetchUserInfo(widget.userEmail);
      final uid =
          userInfo?['id']; // keeping your original global userInfo usage
      print('first email ----> ${widget.userEmail}');
      print('first id ----> ${userInfo?['id'] ?? 'No'}');
      await fetchUserDetails(uid.toString());
      // _applyFilter() will be called inside fetchUserDetails after data is loaded
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
        } else {
          print('Failed to fetch user details');
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  Future<void> deleteUserHistory(List<String> transactionIds) async {
    print('transactionIds $transactionIds');
    try {
      final response = await http.post(
        Uri.parse('${server}showdata/deleteUserTransaction'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "transactionIds": transactionIds.map((id) => int.parse(id)).toList(),
        }),
      );

      print('mohit response ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['success'] == true) {
          print('Deleted successfully');
          final Set<String> deleted = transactionIds.toSet();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Deleted Successful"),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.grey,
            ),
          );
          setState(() {
            userAllDetailsList2.removeWhere(
                (item) => deleted.contains((item['id'] ?? '').toString()));
            selectedIndices.clear();
            isSelectionMode = false;
            hasChanges = true;
          });
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

  void toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      if (!isSelectionMode) {
        selectedIndices.clear();
      }
    });
  }

  void toggleSelection(int index) {
    setState(() {
      if (selectedIndices.contains(index)) {
        selectedIndices.remove(index);
      } else {
        selectedIndices.add(index);
      }
    });
  }

  void selectAll() {
    setState(() {
      if (selectedIndices.length == userAllDetailsList2.length) {
        selectedIndices.clear();
      } else {
        selectedIndices = Set.from(
            List.generate(userAllDetailsList2.length, (index) => index));
      }
    });
  }

  Future<void> deleteSelected() async {
    if (selectedIndices.isEmpty) return;

    final List<String> idsToDelete = selectedIndices
        .map((index) => (userAllDetailsList2[index]['id']).toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (idsToDelete.isEmpty) return;

    await deleteUserHistory(idsToDelete);
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
        userAllDetails['from_user'].isNotEmpty) {
      userName = userAllDetails['from_user'];
    } else if (userAllDetails['to_user'] != null &&
        userAllDetails['to_user'].isNotEmpty) {
      userName = userAllDetails['to_user'];
    }

    String? userImage = userAllDetails['profile_image'];
    String firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : "U";

    return Row(
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
            )
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
          isSelectionMode
              ? 'Select Items (${selectedIndices.length})'
              : 'All Transaction History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Return true if changes were made, false otherwise
            Navigator.pop(context, hasChanges);
          },
        ),
        actions: [
          if (isSelectionMode && selectedIndices.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // deleteSelected();
                showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: Text('Delete Transaction'),
                            content: Text('Are you sure you want to delete?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.black),
                                  )),
                              TextButton(
                                  onPressed: () {
                                    deleteSelected();
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  )),
                            ]));
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Container(
                height: 2.5,
                color: Colors.grey,
              ),
              SizedBox(
                height: 20,
              ),
              if (isSelectionMode && userAllDetailsList2.isNotEmpty)
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: selectedIndices.length ==
                                userAllDetailsList2.length &&
                            userAllDetailsList2.isNotEmpty,
                        onChanged: (bool? value) {
                          selectAll();
                        },
                      ),
                      Text(
                        'Select All (${selectedIndices.length}/${userAllDetailsList2.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      TextButton(
                        onPressed: toggleSelectionMode,
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              LoadingFallbackWidget(
                isLoading: isLoading,
                hasData: userAllDetailsList2.isNotEmpty,
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
                child: SizedBox(),
              ),

              //User Transaction
              for (int index = 0; index < userAllDetailsList2.length; index++)
                Builder(
                  builder: (context) {
                    final userAllDetails = userAllDetailsList2[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isSelectionMode && selectedIndices.contains(index)
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: isSelectionMode &&
                                    selectedIndices.contains(index)
                                ? BorderSide(color: Colors.grey, width: 2)
                                : BorderSide.none,
                          ),
                        ),
                        onPressed: () async {
                          if (isSelectionMode) {
                            toggleSelection(index);
                          } else {
                            String currentUserName = '';
                            print('User id are here ${userInfo?['id']}');
                            if (userAllDetails['to_user'] == '') {
                              currentUserName = userAllDetails['from_user'];
                            } else if (userAllDetails['from_user'] == '') {
                              currentUserName = userAllDetails['to_user'];
                            }
                            print('current user name $currentUserName');
                            print('user all details ${userAllDetails}');
                            print(
                                'user transaction id ${userAllDetails['id']}');

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Usertransaction(
                                  currentUserName: currentUserName,
                                  userId: userAllDetails2?['userId'],
                                  userEmail: userInfo?['email'],
                                ),
                              ),
                            );

                            // If we get back a result indicating changes were made, refresh the data
                            if (result == true) {
                              await loadAllFunction();
                            }
                          }
                        },
                        onLongPress: () {
                          if (!isSelectionMode) {
                            toggleSelectionMode();
                            toggleSelection(index);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (isSelectionMode)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Icon(
                                      selectedIndices.contains(index)
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: selectedIndices.contains(index)
                                          ? Colors.red
                                          : Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                                buildUserProfile(userAllDetails),
                                const SizedBox(width: 10),
                              ],
                            ),
                            Text(
                              (() {
                                String amount = '0'; // Default amount

                                // Check if 'letest_income' is not empty and set the amount
                                if (userAllDetails['letest_income'] != null &&
                                    userAllDetails['letest_income']
                                        .isNotEmpty) {
                                  amount =
                                      '+ ₹${userAllDetails['letest_income']}';
                                }
                                // Check if 'letest_expence' is not empty and set the amount
                                else if (userAllDetails['letest_expence'] !=
                                        null &&
                                    userAllDetails['letest_expence']
                                        .isNotEmpty) {
                                  amount =
                                      '- ₹${userAllDetails['letest_expence']}';
                                }

                                return amount;
                              })(),
                              style: TextStyle(
                                color: (() {
                                  // Determine color based on whether income or expense is present
                                  if (userAllDetails['letest_income'] != null &&
                                      userAllDetails['letest_income']
                                          .isNotEmpty) {
                                    return Colors.green; // Green for income
                                  } else if (userAllDetails['letest_expence'] !=
                                          null &&
                                      userAllDetails['letest_expence']
                                          .isNotEmpty) {
                                    return Colors.red; // Red for expense
                                  } else {
                                    return Colors
                                        .black; // Fallback to black if no income or expense
                                  }
                                })(),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
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
