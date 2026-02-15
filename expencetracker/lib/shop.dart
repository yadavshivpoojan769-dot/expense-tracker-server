import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:expencetracker/impVar.dart';
import 'package:expencetracker/searchShopkeeper.dart';
import 'package:expencetracker/shopkeeper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class Shop extends StatefulWidget {
  final String userEmail;
  const Shop({super.key, required this.userEmail});

  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> {
  Map<String, dynamic>? userInfo;
  // TextEditingController title = TextEditingController();
  // TextEditingController amount = TextEditingController();
  // TextEditingController date = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // List<Map<String, dynamic>> transactionDetails = [];
  // TextEditingController to = TextEditingController();
  // TextEditingController enteredAmount = TextEditingController();
  // List<TextEditingController> toControllers = [];
  // List<TextEditingController> amountControllers = [];

  final List<String> imageUrls = [
    'https://5.imimg.com/data5/NN/NN/GLADMIN-/aashirvaad-whole-wheat-atta.jpg',
    'https://www.gorevizon.com/wp-content/uploads/2020/07/x1-36.jpg',
    'https://swagatgrocery.com/cdn/shop/articles/10-Must-Have-Items-on-Your-Indian-Grocery-Shopping-List.jpg?v=1753876796',
    'https://i0.wp.com/www.opindia.com/wp-content/uploads/2021/05/Amul-the-taste-of-India-29052021.jpg?fit=1200%2C675&ssl=1',
  ];

  void initState() {
    super.initState();
    fetchUserInfo(widget.userEmail);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Shopping',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/etshop.png',
                    height: 80,
                    width: 80,
                    // width: MediaQuery.of(context).size.width * 0.5,
                    // height: MediaQuery.of(context).size.height * 0.5
                  ),
                  // SizedBox(
                  //   height: 5,
                  // ),
                  // Text(
                  //   "Expense Tracker Shopping",
                  //   style: TextStyle(
                  //       color: Colors.black,
                  //       fontSize: 20,
                  //       fontWeight: FontWeight.bold),
                  // ),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue, Colors.purple],
                    ).createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                    child: Text(
                      'Expense Tracker Shopping',
                      style: GoogleFonts.raleway(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors
                            .white, // Color must be set for ShaderMask to work
                      ),
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color.fromARGB(255, 139, 141, 1),
                        const Color.fromARGB(255, 41, 37, 0)
                      ],
                    ).createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                    child: Text(
                      'Spend Smarter, Save More. ',
                      style: GoogleFonts.raleway(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors
                            .white, // Color must be set for ShaderMask to work
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(
                    width: 10,
                  ),
                  Text("My Account"),
                ],
              ),
              onTap: () {},
            ),
            ListTile(
              title: Row(
                children: [
                  Icon(Icons.shopping_cart),
                  SizedBox(
                    width: 10,
                  ),
                  Text("My Orders"),
                ],
              ),
              onTap: () {},
            ),
            ListTile(
              title: Row(
                children: [
                  Icon(Icons.favorite),
                  SizedBox(
                    width: 10,
                  ),
                  Text("Wish List"),
                ],
              ),
              onTap: () {},
            ),
            ListTile(
              title: Row(
                children: [
                  Icon(Icons.search),
                  SizedBox(
                    width: 10,
                  ),
                  Text("Search shopkeepers near you"),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        Searchshopkeeper(userEmail: userInfo?['email'] ?? ''),
                  ),
                );
              },
            ),
            ListTile(
              title: Row(
                children: [
                  Icon(Icons.group),
                  SizedBox(
                    width: 10,
                  ),
                  Text("Added shopkeepers"),
                ],
              ),
              onTap: () {},
            ),
            ListTile(
              title: Row(
                children: [
                  Icon(Icons.account_circle_rounded),
                  SizedBox(
                    width: 10,
                  ),
                  Text("Shopkeeper Account"),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        Shopkeeper(userEmail: userInfo?['email'] ?? ''),
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 236, 236, 236),
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
                height: 10,
              ),
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
                    hintText: 'Search for your local shop or products',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) {
                    setState(() {}); // rebuild UI whenever text changes
                  },
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Row(
                  children: [
                    Text(
                      'Sponsored',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              CarouselSlider(
                options: CarouselOptions(
                  height: 120.0,
                  autoPlay: true,
                  autoPlayInterval: Duration(seconds: 3),
                  enlargeCenterPage: true,
                  aspectRatio: 16 / 9,
                  viewportFraction: 0.9,
                ),
                items: imageUrls.map((url) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.symmetric(horizontal: 1.0),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  );
                }).toList(),
              ),

              SizedBox(
                height: 10,
              ),
              //Stttttttt
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 15,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order now',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            // color: Colors.black,
                          ),
                        ),
                        TextButton(
                            onPressed: () {},
                            child: Text(
                              'See all',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                // fontWeight: FontWeight.bold
                              ),
                            ))
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dairy:',
                          style: TextStyle(
                            // color: Colors.black,
                            fontSize: 16,
                            // fontWeight: FontWeight.bold
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
//Sttttttttrrrrrrrrrrrrrrr
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
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: MediaQuery.of(context).size.width * 0.62,
                          decoration: BoxDecoration(
                            color: Colors.white, // Move color here
                            // border: Border.all(
                            //   color: Colors.blue, // Border color
                            //   width: 2.0, // Border width
                            // ),
                            borderRadius:
                                BorderRadius.circular(8), // Rounded corners
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.black,
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
                                Text('Amul Taaza Homogenised Toned Milk'),
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
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                    Text(
                                      '4.7☆',
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 12),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
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
                                        decoration: TextDecoration.lineThrough,
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
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: MediaQuery.of(context).size.width * 0.62,
                          decoration: BoxDecoration(
                            color: Colors.white, // Move color here
                            // border: Border.all(
                            //   color: Colors.blue, // Border color
                            //   width: 2.0, // Border width
                            // ),
                            borderRadius:
                                BorderRadius.circular(8), // Rounded corners
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.black,
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
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                    Text(
                                      '4.2☆',
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 12),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
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
                                        decoration: TextDecoration.lineThrough,
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
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: MediaQuery.of(context).size.width * 0.62,
                          decoration: BoxDecoration(
                            color: Colors.white, // Move color here
                            // border: Border.all(
                            //   color: Colors.blue, // Border color
                            //   width: 2.0, // Border width
                            // ),
                            borderRadius:
                                BorderRadius.circular(8), // Rounded corners
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.black,
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
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                    Text(
                                      '4.4☆',
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 12),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
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
                                        decoration: TextDecoration.lineThrough,
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
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 15,
                ),
                child: Row(
                  children: [
                    Text(
                      'Grocery:',
                      style: TextStyle(
                        // color: Colors.black,
                        fontSize: 16,
                        // fontWeight: FontWeight.bold
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    // horizontal: 15,
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
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: MediaQuery.of(context).size.width * 0.62,
                          decoration: BoxDecoration(
                            color: Colors.white, // Move color here
                            // border: Border.all(
                            //   color: Colors.blue, // Border color
                            //   width: 2.0, // Border width
                            // ),
                            borderRadius:
                                BorderRadius.circular(8), // Rounded corners
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.black,
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
                            onPressed: () {
                              print('Button Pressed');
                            },
                            child: Column(
                              children: [
                                Image.network(
                                  'https://encrypted-tbn0.gstatic.com/shopping?q=tbn:ANd9GcSAXrNRMGBB7m2EqkS7g5F8SZYMS8NeSG7cuN0i1LBucRejR_044hS1UI5qwe_H67WXwmoKNV226p11JpddG4HpZaw9-x_unoPSWbFXIHYrzwz9ibY7vaYOsg',
                                  height: 150,
                                  width: 150,
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text('India Gate Basmati Rice Feast Rozzana'),
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '5 kg',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                    Text(
                                      '4.8☆',
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 12),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₹499',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      '₹799',
                                      style: TextStyle(
                                        fontSize: 15,
                                        // fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
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
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: MediaQuery.of(context).size.width * 0.62,
                          decoration: BoxDecoration(
                            color: Colors.white, // Move color here
                            // border: Border.all(
                            //   color: Colors.blue, // Border color
                            //   width: 2.0, // Border width
                            // ),
                            borderRadius:
                                BorderRadius.circular(8), // Rounded corners
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.black,
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
                            onPressed: () {
                              print('Button Pressed');
                            },
                            child: Column(
                              children: [
                                Image.network(
                                  'https://encrypted-tbn0.gstatic.com/shopping?q=tbn:ANd9GcQ3iziHMNRs3FeARti4bY9WQj1FIybtRUibDtqlftuc6VpIH-Ldbb0pAygWri-oHDRGhUryxbNjVgt2-a6pJM15383Rj1-6nVow652L_-qDtocYbS_anEkenw',
                                  height: 150,
                                  width: 150,
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text('Fortune Sunlite Refined Oil'),
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '1ltr',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                    Text(
                                      '4.4☆',
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 12),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₹155',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      '₹169',
                                      style: TextStyle(
                                        fontSize: 15,
                                        // fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
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
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: MediaQuery.of(context).size.width * 0.62,
                          decoration: BoxDecoration(
                            color: Colors.white, // Move color here
                            // border: Border.all(
                            //   color: Colors.blue, // Border color
                            //   width: 2.0, // Border width
                            // ),
                            borderRadius:
                                BorderRadius.circular(8), // Rounded corners
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.black,
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
                            onPressed: () {
                              print('Button Pressed');
                            },
                            child: Column(
                              children: [
                                Image.network(
                                  'https://encrypted-tbn3.gstatic.com/shopping?q=tbn:ANd9GcQVlca_B9pB7Gl2-t3ajb3G6Tn_vHysN7ysluptRijyokMnoXyU40IRbKsPaq8_gFAgD5tsghJ5oFjoet9EIFxLDHZSIeeYqoSQP8B0sWwtvu6r4wPczes2BA',
                                  height: 150,
                                  width: 150,
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text('Aashirvaad Shudh Chakki Atta'),
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '5 kg',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                    Text(
                                      '4.5☆',
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 12),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₹180',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      '₹199',
                                      style: TextStyle(
                                        fontSize: 15,
                                        // fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
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
        ),
      ),
    );
  }
}
