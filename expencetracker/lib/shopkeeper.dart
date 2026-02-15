import 'dart:convert';

import 'package:expencetracker/addShopkeeper.dart';
import 'package:expencetracker/impVar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class Shopkeeper extends StatefulWidget {
  final String userEmail;
  const Shopkeeper({super.key, required this.userEmail});

  @override
  State<Shopkeeper> createState() => _ShopkeeperState();
}

Map<String, dynamic>? userInfo;
Map<String, dynamic>? shopInfo;
String currentUid = '';
bool userStatus = false;

class _ShopkeeperState extends State<Shopkeeper> {
  void initState() {
    super.initState();
    loadAllFunction();
  }

  Future<void> loadAllFunction() async {
    await fetchUserInfo(widget.userEmail);
    String currentUid = userInfo?['id'].toString() ?? '';
    print('Current UID: $currentUid');
    await fetchShopkeeperInfo(currentUid);
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

  Future<void> fetchShopkeeperInfo(String currentUid) async {
    // String currentUid = userInfo?['id'].toString() ?? '';
    print('uidddddddddddd $currentUid');
    try {
      final response = await http.post(
        Uri.parse('${server}showdata/shopkeeperInfo'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"uid": currentUid}),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody is List && responseBody.isNotEmpty) {
          setState(() {
            shopInfo = responseBody[0] as Map<String, dynamic>;
            userStatus = false;
          });
          print('Shopkeeper info -> $shopInfo');
        } else {
          print('No user found');
          shopInfo = null;
          setState(() {
            userStatus = true;
          });
        }
      } else {
        print('Failed to load shop info');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> deleteshopkeeper(String shopId) async {
    try {
      final response = await http.post(
        Uri.parse('${server}showdata/deleteShopkeeper'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({"id": shopId}),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        if (responseBody['success'] == true) {
          print('Deleted successfully');
          setState(() {});
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  Shopkeeper(userEmail: userInfo?['email'] ?? ''),
            ),
          );
          await fetchShopkeeperInfo((userInfo?['id']));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${shopInfo?['shopname'] ?? 'Shop Account'}',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: InkWell(
                onTap: () {
                  Scaffold.of(context)
                      .openEndDrawer(); // 👈 opens right-side drawer
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: (shopInfo?['image'] != null &&
                          shopInfo!['image'].toString().trim().isNotEmpty &&
                          shopInfo!['image'].toString().trim().toLowerCase() !=
                              'null')
                      ? NetworkImage(
                          '${server}${shopInfo!['image']}'
                              .replaceAll('\\', '/'),
                        )
                      : const NetworkImage(
                          'https://img.freepik.com/free-vector/blue-circle-with-white-user_78370-4707.jpg',
                        ),
                ),
              ),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: (shopInfo?['image'] != null &&
                            shopInfo!['image'].toString().trim().isNotEmpty &&
                            shopInfo!['image']
                                    .toString()
                                    .trim()
                                    .toLowerCase() !=
                                'null')
                        ? NetworkImage(
                            '${server}${shopInfo!['image']}'
                                .replaceAll('\\', '/'),
                          )
                        : const NetworkImage(
                            'https://img.freepik.com/free-vector/blue-circle-with-white-user_78370-4707.jpg',
                          ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    "${shopInfo?['shopname'] ?? 'Shop Account'}",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () async {
                      final address = shopInfo?['address'] ?? 'Noida';
                      final query = Uri.encodeComponent(address);

                      // Try geo scheme first (preferred on mobile)
                      final Uri googleUrl = Uri.parse("geo:0,0?q=$query");

                      if (await canLaunchUrl(googleUrl)) {
                        await launchUrl(googleUrl,
                            mode: LaunchMode.externalApplication);
                      } else {
                        // fallback to web URL
                        final fallbackUrl = Uri.parse(
                            "https://www.google.com/maps/search/?api=1&query=$query");
                        if (await canLaunchUrl(fallbackUrl)) {
                          await launchUrl(fallbackUrl,
                              mode: LaunchMode.externalApplication);
                        } else {
                          throw 'Could not open the map.';
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.grey,
                          size: 17,
                        ),
                        Text(
                          " ${shopInfo?['address'] ?? 'Address'}",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            // fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Row(
                children: [
                  Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Delete account",
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
              onTap: () {
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
                              Color.fromARGB(255, 253, 253, 253),
                              Color.fromARGB(255, 190, 189, 190),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete),
                                SizedBox(width: 5),
                                Text(
                                  "Confirm Delete",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            Text(
                              "Are you sure you want to delete your shopping account?",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    "No",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                TextButton(
                                  onPressed: () {
                                    final shopId = shopInfo?['id']?.toString();
                                    if (shopId != null && shopId.isNotEmpty) {
                                      deleteshopkeeper(shopId);
                                    } else {
                                      print("User ID is null or empty!");
                                    }
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    "Yes",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
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
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 236, 236, 236),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 2,
              color: Colors.grey,
            ),
            SizedBox(
              height: 10,
            ),
            userStatus == true
                ? Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.025,
                    ),
                    child: Container(
                      child: Column(
                        children: [
                          Text(
                            'Dear ${userInfo?['name'] ?? 'user'}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              // fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'You don\'t have an account as a shopkeeper',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              // fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            height: 20,
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Addshopkeeper(
                                        userEmail: widget.userEmail),
                                  ),
                                );
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
                              child: Text('Add Account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Text("Hello ${userInfo?['name'] ?? 'user'}"),
                      Text(
                        'Your Products',
                        style: TextStyle(
                          // fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row(
                            //   children: [
                            //     Text(
                            //       'Your Products',
                            //       style: TextStyle(
                            //         // fontWeight: FontWeight.bold,
                            //         fontSize: 18,
                            //         color: Colors.black,
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            // SizedBox(
                            //   height: 10,
                            // ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Dairy',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    // fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),

                      //Sttttttttttttt
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 0,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            height: MediaQuery.of(context).size.width * 0.7,
                            color: Colors.grey,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 15,
                                ),
                                //Startttt
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.4,
                                  height:
                                      MediaQuery.of(context).size.width * 0.62,
                                  decoration: BoxDecoration(
                                    color: Colors.white, // Move color here
                                    // border: Border.all(
                                    //   color: Colors.blue, // Border color
                                    //   width: 2.0, // Border width
                                    // ),
                                    borderRadius: BorderRadius.circular(
                                        8), // Rounded corners
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.black,
                                      shadowColor: Colors.transparent,
                                      elevation: 5,
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            MediaQuery.of(context).size.width *
                                                0.025,
                                      ),
                                      textStyle: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      print('Button Pressed');
                                    },
                                    child: Column(
                                      children: [
                                        Image.network(
                                          'https://instamart-media-assets.swiggy.com/swiggy/image/upload/fl_lossy,f_auto,q_auto,h_600/xrj8lmdwtc3ll27s9wvc',
                                          height: 130,
                                          width: 130,
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                            'Amul Taaza Homogenised Toned Milk'),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '240 ml',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12),
                                            ),
                                            Text(
                                              '4.7☆',
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              '₹49',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              '₹115',
                                              style: TextStyle(
                                                fontSize: 15,
                                                // fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 15,
                                ),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.4,
                                  height:
                                      MediaQuery.of(context).size.width * 0.62,
                                  decoration: BoxDecoration(
                                    color: Colors.white, // Move color here
                                    // border: Border.all(
                                    //   color: Colors.blue, // Border color
                                    //   width: 2.0, // Border width
                                    // ),
                                    borderRadius: BorderRadius.circular(
                                        8), // Rounded corners
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.black,
                                      shadowColor: Colors.transparent,
                                      elevation: 5,
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            MediaQuery.of(context).size.width *
                                                0.025,
                                      ),
                                      textStyle: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      print('Button Pressed');
                                    },
                                    child: Column(
                                      children: [
                                        Image.network(
                                          'https://www.jiomart.com/images/product/original/491264515/godrej-jersey-soft-paneer-200-g-pack-product-images-o491264515-p590032673-0-202402081834.jpg?im=Resize=(1000,1000)',
                                          height: 150,
                                          width: 150,
                                        ),
                                        Text('Godrej Jersy Soft Paneer'),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '200 g',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12),
                                            ),
                                            Text(
                                              '4.2☆',
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              '₹149',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              '₹299',
                                              style: TextStyle(
                                                fontSize: 15,
                                                // fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 15,
                                ),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.4,
                                  height:
                                      MediaQuery.of(context).size.width * 0.62,
                                  decoration: BoxDecoration(
                                    color: Colors.white, // Move color here
                                    // border: Border.all(
                                    //   color: Colors.blue, // Border color
                                    //   width: 2.0, // Border width
                                    // ),
                                    borderRadius: BorderRadius.circular(
                                        8), // Rounded corners
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.black,
                                      shadowColor: Colors.transparent,
                                      elevation: 5,
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            MediaQuery.of(context).size.width *
                                                0.025,
                                      ),
                                      textStyle: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      print('Button Pressed');
                                    },
                                    child: Column(
                                      children: [
                                        Image.network(
                                          'https://rukminim2.flixcart.com/image/704/844/xif0q/curd-yogurt/g/x/p/-original-imahccx2pwyvhzhg.jpeg?q=90&crop=false',
                                          height: 150,
                                          width: 150,
                                        ),
                                        Text('Amul Dahi Pouch Plain Curd NA'),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '800 ml',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12),
                                            ),
                                            Text(
                                              '4.4☆',
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              '₹60',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              '₹109',
                                              style: TextStyle(
                                                fontSize: 15,
                                                // fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 15,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        )),
      ),
      floatingActionButton: SizedBox(
        width: 60, // Default is 56, so increase as needed
        height: 60,
        child: FloatingActionButton(
          onPressed: () {
            // title.clear();
            // openAddProductDialog();
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
