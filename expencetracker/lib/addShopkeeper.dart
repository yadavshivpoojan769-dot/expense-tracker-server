import 'dart:convert';
import 'dart:io';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:expencetracker/impVar.dart';
import 'package:expencetracker/shopkeeper.dart';
import 'package:expencetracker/utils/routes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class Addshopkeeper extends StatefulWidget {
  final String userEmail;
  const Addshopkeeper({super.key, required this.userEmail});

  @override
  State<Addshopkeeper> createState() => _AddshopkeeperState();
}

class _AddshopkeeperState extends State<Addshopkeeper> {
  Map<String, dynamic>? userInfo;
  bool viewpass = true;
  bool viewpass2 = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController shopName = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController address = TextEditingController();
  TextEditingController shopType = TextEditingController();
  TextEditingController uid = TextEditingController();
  // TextEditingController confirmpass = TextEditingController();
  String? emailError;
  PlatformFile? pickedFile;
  // final path = pickedFile?.path;

  String namehint = 'Name';
  String emailhint = 'Email';
  String phonehint = 'Phone';
  String passhint = 'Password';
  String cnfpasshint = 'Confirm Password';
  bool emailExists = false;
  bool isLoading = false;
  String errorMessage = '';

  List<String> shopTypes = [
    "Grocery Store",
    "Vegetable Shop",
    "Fruit Shop",
    "Medical Store",
    "Clothing Store",
    "Footwear Shop",
    "Jewellery Shop",
    "Stationery Shop",
    "Hardware Store",
    "Electrical Shop",
    "Electronics Store",
    "Mobile Shop",
    "Furniture Store",
    "Bookstore",
    "Gift Shop",
    "Cosmetics Shop",
    "Tailor Shop",
    "Watch Shop",
    "Sweet Shop",
    "Bakery",
    "Meat Shop",
    "Fish Market",
    "Dairy Shop",
    "Tea Stall",
    "Pan Shop",
    "General Store",
    "Provision Store",
    "Spare Parts Shop",
    "Cycle Repair Shop",
    "Auto Parts Shop",
    "Salon",
    "Barber Shop",
    "Beauty Parlour",
    "Internet Cafe",
    "Printing Shop",
    "Photo Studio",
    "Paint Shop",
    "Plastic Goods Shop",
    "Home Decor Shop",
    "Toy Shop",
    "Pet Store",
    "Agro Shop",
    "Seed and Fertilizer Shop",
    "Ayurvedic Store",
    "Handicraft Shop",
    "Dry Fruit Store",
    "Textile Shop",
    "Luggage Store",
    "Second-hand Goods Shop",
    "Music Instrument Store",
    "Religious Items Shop",
    "Crockery Store",
    "Utensil Shop",
    "Carpentry Store",
    "Mobile Repair Shop",
    "Recharge and SIM Shop",
    "Tattoo Studio",
    "Shoe Repair Shop",
    "Curtain and Furnishing Store",
    "Mattress Shop",
    "Sports Goods Store",
    "Bicycle Store",
    "Lock and Key Shop",
    "Pawn Shop",
    "Scrap Dealer",
    "Ice Cream Parlour",
    "Juice Center",
    "Restaurant",
    "Café",
    "Fast Food Center",
    "Flower Shop",
    "Sanitaryware Store",
    "Building Material Store",
    "Paint and Hardware Shop",
    "Paper and Packaging Store",
    "Event Decoration Shop",
    "Toys and Games Shop",
    "Artificial Jewellery Shop",
    "Organic Products Store",
    "Thrift Store",
    "Baby Products Store",
    "Language Bookstore",
    "Photo Frame Shop",
    "Old Newspaper Buyer",
    "Lighting Store",
    "Namkeen and Snacks Shop",
    "Bangles Shop",
    "Plastic Recycle Shop",
    "Sari Shop",
    "Kirana Store",
    "Cold Storage Shop",
    "Mobile Accessories Shop",
    "LPG Agency",
    "Kitchenware Store",
    "Herbal Products Shop",
    "Charcoal and Wood Shop",
    "Incense and Puja Items Shop",
    "E-waste Collection Shop"
  ];

  void initState() {
    super.initState();
    fetchUserInfo(widget.userEmail);
    // print(userInfo);
  }

  void checkInput() {
    if (_formKey.currentState!.validate()) {
      Addshopkeeper();
    }
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

  Future<void> Addshopkeeper() async {
    setState(() {
      isLoading = true;
      errorMessage = ''; // Reset any previous error message
    });
    Future.delayed(Duration(seconds: 5), () {
      if (isLoading) {
        setState(() {
          errorMessage = 'Server is not responding...';
          isLoading = false; // Stop the loading indicator after 3 seconds
        });
      }
    });

    try {
      var uri =
          Uri.parse('http://172.18.96.251:55000/signup/shopkeeper/insert');
      var request = http.MultipartRequest('POST', uri);

      // Add text fields
      request.fields['shopname'] = shopName.text;
      request.fields['email'] = userInfo?['email'] ?? '';
      request.fields['phone'] = phone.text;
      request.fields['shoptype'] = shopType.text;
      request.fields['uid'] = userInfo?['id'].toString() ?? '';
      request.fields['address'] = address.text;

      if (pickedFile != null && pickedFile!.path != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file', // This must match multer's field name: upload.single('file')
          pickedFile!.path!,
        ));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        print("User registered successfully");
        // Navigator.of(context).pushReplacement(
        //   MaterialPageRoute(builder: (context) => Login()),
        // );
        // Navigator.push(context, MyRoutes());
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                Shopkeeper(userEmail: userInfo?['email'] ?? ''),
          ),
        );
        // Navigator.pop(context);
      } else {
        setState(() {
          errorMessage = 'Server is not responding...';
        });
        print('Failed to register user: ${response.statusCode}');
      }
    } catch (error) {
      print('Sign up error: $error');
      setState(() {
        errorMessage = 'Server is not responding...';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          pickedFile = result.files.first;
          print('Picked file: ${pickedFile}');
        });
      }
    } catch (error) {
      print('Error picking image: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue, Colors.purple],
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
              child: Text(
                'Add Account',
                style: GoogleFonts.raleway(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color:
                      Colors.white, // Color must be set for ShaderMask to work
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            GestureDetector(
                onTap: _pickImage,
                child: Stack(alignment: Alignment.center, children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey,
                    child: pickedFile != null
                        ? ClipOval(
                            child: Image.file(
                              File(pickedFile!.path!),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.home_work,
                            size: 50,
                            color: Colors.white,
                          ),
                  ),
                  Positioned(
                      top: 0,
                      left: 65,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ))
                ])),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    //Name Field
                    TextFormField(
                      controller: shopName,
                      keyboardType: TextInputType.text,
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        prefixIcon: Icon(Icons.person),
                        fillColor: Colors.grey[100],
                        filled: true,
                        hintText: 'Shop Name',
                        labelText: 'Shop Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your shop name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.number,
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        prefixIcon: Icon(Icons.phone),
                        fillColor: Colors.grey[100],
                        filled: true,
                        hintText: "Phone",
                        labelText: "Phone",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length != 10) {
                          return 'Phone number must be 10 digits';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),
                    DropdownSearch<String>(
                      items: (String? filter, dynamic _scroll) {
                        final list = shopTypes
                            .where((item) =>
                                filter == null ||
                                item
                                    .toLowerCase()
                                    .contains(filter.toLowerCase()))
                            .toList();
                        return list;
                      },
                      selectedItem:
                          shopType.text.isNotEmpty ? shopType.text : null,
                      onChanged: (value) {
                        shopType.text = value ?? '';
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        menuProps: MenuProps(
                          backgroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: "Search shop type",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: "Select your shop type",
                          hintText: "Select your shop type",
                          prefixIcon: Icon(Icons.shopify_rounded),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                BorderSide(color: Colors.grey, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your shop type';
                        }
                        return null;
                      },
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      controller: address,
                      keyboardType: TextInputType.text,
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        prefixIcon: Icon(Icons.home_work_outlined),
                        fillColor: Colors.grey[100],
                        filled: true,
                        hintText: 'Shop Address',
                        labelText: 'Shop Address',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your shop address';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              //column
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
                borderRadius: BorderRadius.circular(50),
              ),
              child: ElevatedButton(
                onPressed: checkInput,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  padding: EdgeInsets.symmetric(horizontal: 130, vertical: 15),
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: isLoading
                    ? Container(
                        width: 20.0, // Set your desired width
                        height: 20.0, // Set your desired height
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        "Add",
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Ensure contrast over gradient
                        ),
                      ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$errorMessage',
                      style: TextStyle(color: Colors.red),
                    ),
                    TextButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                              context, MyRoutes.Signup, (route) => false);
                        },
                        child: Text(
                          'Try again',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ))
                  ],
                ),
              ),
          ],
        )),
      ),
    );
  }
}
