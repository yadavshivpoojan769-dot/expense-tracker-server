import 'dart:convert';

import 'package:expencetracker/impVar.dart';
import 'package:expencetracker/userTransaction.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Searchbar extends StatefulWidget {
  final String userEmail;
  const Searchbar({super.key, required this.userEmail});

  @override
  State<Searchbar> createState() => _SearchbarState();
}

// Keep these if other parts of the app rely on them
List<Map<String, dynamic>> userAllDetailsList2 = [];
Map<String, dynamic>? userAllDetails2;

class _SearchbarState extends State<Searchbar> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredList = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilter);
    loadAllFunction();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadAllFunction() async {
    await fetchUserInfo(widget.userEmail);
    final uid = userInfo?['id']; // keeping your original global userInfo usage
    print('first email -> ${widget.userEmail}');
    print('first id -> ${userInfo?['id'] ?? 'No'}');
    await fetchUserDetails(uid.toString());
    // _applyFilter() will be called inside fetchUserDetails after data is loaded
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
          // Update filtered list after fetching data
          _applyFilter();
          setState(() {});
        } else {
          print('Failed to fetch user details');
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  // Helper to compute a display name for an entry
  String _displayName(Map<String, dynamic> item) {
    final from = (item['from_user'] ?? '').toString().trim();
    final to = (item['to_user'] ?? '').toString().trim();
    if (from.isNotEmpty) return from;
    if (to.isNotEmpty) return to;
    return 'Name';
  }

  // Filtering logic (case-insensitive search in from_user or to_user)
  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        // Show all unique entries when search is empty
        final uniqueMap = <String, Map<String, dynamic>>{};
        for (var user in userAllDetailsList2) {
          final nameKey = _displayName(user).toLowerCase();
          if (!uniqueMap.containsKey(nameKey)) {
            uniqueMap[nameKey] = user;
          }
        }
        _filteredList = uniqueMap.values.toList();
      } else {
        // Filter first
        var filtered = userAllDetailsList2.where((user) {
          final name = _displayName(user).toLowerCase();
          return name.contains(query);
        }).toList();

        // Remove duplicates by name
        final uniqueMap = <String, Map<String, dynamic>>{};
        for (var user in filtered) {
          final nameKey = _displayName(user).toLowerCase();
          if (!uniqueMap.containsKey(nameKey)) {
            uniqueMap[nameKey] = user;
          }
        }
        _filteredList = uniqueMap.values.toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Search',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            // You can keep the icon for other actions; search field is in body
            IconButton(onPressed: () {}, icon: Icon(Icons.filter_list))
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Container(height: 2.5, color: Colors.grey),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  controller: _searchController,
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                    hintText: 'Search by name',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilter();
                            },
                          )
                        : null,
                    // border: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(8),
                    // ),
                  ),
                  onChanged: (_) {
                    // _applyFilter is already called by listener, but harmless to call again
                    _applyFilter();
                  },
                ),
              ),

              // Show "No transaction history" when nothing to show
              if (_searchController.text.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.network(
                      'https://cdn-icons-png.flaticon.com/512/5680/5680244.png',
                      // height: 50,
                      width: 150),
                )
              else if (_filteredList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                  child: Column(children: [
                    SizedBox(height: 10),
                    Text('No transaction history with this name',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        )),
                  ]),
                )
              else
                // Render the filtered results
                for (var userAllDetails in _filteredList)
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        print('User id are here ${userAllDetails['userId']}');
                        final currentUserName =
                            _displayName(userAllDetails); // use same helper
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
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Image.network(
                                  'https://img.freepik.com/premium-vector/user-icon-round-grey-icon_1076610-44912.jpg?w=360',
                                  height: 50,
                                  width: 50),
                              SizedBox(width: 10),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _displayName(userAllDetails),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // If you want a trailing amount or arrow, add here
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
