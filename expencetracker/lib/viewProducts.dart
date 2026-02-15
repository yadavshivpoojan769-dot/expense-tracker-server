import 'dart:convert';

import 'package:expencetracker/impVar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Viewproducts extends StatefulWidget {
  final String userId;
  final int id;
  const Viewproducts({super.key, required this.userId, required this.id});

  @override
  State<Viewproducts> createState() => _ViewproductsState();
}

// int productId = 0;

class _ViewproductsState extends State<Viewproducts> {
  List<Map<String, TextEditingController>> localControllers = [
    {'productName': TextEditingController()}
  ];
  List<Map<String, dynamic>> userAllDetailsList2 = [];
  Map<String, dynamic>? userAllDetails2;
  List<bool> _isChecked = [];
  bool isEditing = false;
  List<TextEditingController> _productControllers = [];
  bool isLoading = false;
  Map<String, dynamic>? allProducts;
  List<Map<String, dynamic>> allproductList = [];
  Set<int> _selectedIndexes = {};
  bool checked = false;
  bool showShareButton = false;
  String copiedText = '';

  void initState() {
    super.initState();
    loadAllFunction();
  }

  // Save checkbox states to SharedPreferences
  Future<void> _saveCheckboxStates() async {
    try {
      // Only save if the list is properly initialized and not empty
      if (_isChecked.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final key = 'checkbox_states_${widget.userId}_${widget.id}';
        await prefs.setStringList(
            key, _isChecked.map((checked) => checked.toString()).toList());
      }
    } catch (e) {
      print('Error saving checkbox states: $e');
    }
  }

  // Load checkbox states from SharedPreferences
  Future<void> _loadCheckboxStates() async {
    try {
      // First synchronize the checkbox list to ensure correct length
      _synchronizeCheckboxList();

      final prefs = await SharedPreferences.getInstance();
      final key = 'checkbox_states_${widget.userId}_${widget.id}';
      final savedStates = prefs.getStringList(key);

      if (savedStates != null) {
        // Create a new list with the correct length
        final newCheckedList = List<bool>.filled(_isChecked.length, false);

        // Copy saved states up to the minimum length
        final minLength = savedStates.length < _isChecked.length
            ? savedStates.length
            : _isChecked.length;

        for (int i = 0; i < minLength; i++) {
          newCheckedList[i] = savedStates[i] == 'true';
        }

        setState(() {
          _isChecked = newCheckedList;
        });
      }
    } catch (e) {
      print('Error loading checkbox states: $e');
      // If there's an error, reset to all false
      setState(() {
        _isChecked = List<bool>.filled(_isChecked.length, false);
      });
    }
  }

  // Clear all checkbox states for this product list
  Future<void> _clearCheckboxStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'checkbox_states_${widget.userId}_${widget.id}';
      await prefs.remove(key);
    } catch (e) {
      print('Error clearing checkbox states: $e');
    }
  }

  // Reset all checkboxes to unchecked state
  Future<void> _resetAllCheckboxes() async {
    setState(() {
      _isChecked = List<bool>.filled(_isChecked.length, false);
    });
    await _saveCheckboxStates();
  }

  // Get parsed product list
  List<Map<String, dynamic>> getParsedProducts(
      Map<String, dynamic> productData) {
    try {
      if (productData['productName'] is String) {
        // Parse JSON string to list
        final List<dynamic> parsed = json.decode(productData['productName']);
        return List<Map<String, dynamic>>.from(parsed);
      } else if (productData['productName'] is List) {
        // Already parsed
        return List<Map<String, dynamic>>.from(productData['productName']);
      }
      return [];
    } catch (e) {
      print('Error parsing products: $e');
      return [];
    }
  }

  // Validate that we're working with the correct product data
  bool validateProductData(Map<String, dynamic> productData) {
    if (productData.isEmpty) return false;
    if (productData['id'] != widget.id) {
      print(
          'Warning: Product ID mismatch. Expected ${widget.id}, got ${productData['id']}');
      return false;
    }
    return true;
  }

  // Synchronize checkbox list with product list
  void _synchronizeCheckboxList() {
    // Find the current product data
    final currentProduct = allproductList.firstWhere(
      (product) => product['id'] == widget.id,
      orElse: () => {},
    );

    if (currentProduct.isEmpty) {
      print('Warning: No product found for ID ${widget.id}');
      return;
    }

    final parsedProducts = getParsedProducts(currentProduct);
    final productCount = parsedProducts.length;

    print(
        'Synchronizing checkboxes for product ID ${widget.id}: $productCount products');

    if (_isChecked.length != productCount) {
      setState(() {
        _isChecked = List<bool>.filled(productCount, false);
      });
      print(
          'Updated checkbox list length from ${_isChecked.length} to $productCount');
    }
  }

  @override
  void dispose() {
    for (var controller in _productControllers) {
      controller.dispose();
    }
    // Clear selected indexes when widget is disposed
    _selectedIndexes.clear();
    // Hide share button when widget is disposed
    showShareButton = false;
    super.dispose();
  }

  Future<void> loadAllFunction() async {
    await fetchUserDetails(widget.userId);
    print('first id -> ${widget.userId}');
    final uid = widget.userId;
    print('First id --  ${widget.id}');
    print('Userrriddd = ${uid}');
    await fetchProducts((uid).toString());
    // Clear selected indexes when data is refreshed
    _selectedIndexes.clear();
    // Load saved checkbox states after initializing the list
    await _loadCheckboxStates();
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
        } else {
          print('Failed to fetch user details');
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
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
          isLoading = false;
          setState(() {});
          // Load saved checkbox states after fetching products
          await _loadCheckboxStates();
          print('Products >>  $allproductList');
          // print('Product idssss ${allproductList?['id']}');
        } else {
          print('Failed to fetch budget transaction');
          setState(() {
            isLoading = true;
          });
        }
      }
    } catch (err) {
      print('Error fetching budget transaction: $err');
    }
  }

  // Inside _ViewproductsState class

  Future<void> addNewProducts(List<String> newProductNames) async {
    // Check if there are any products to add
    if (newProductNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No new products to add.')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
            '${server}userdetails/products/add'), // <-- Use the new endpoint
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': widget.id, // The ID of the product list to update
          'newProducts': newProductNames, // The list of new product names
        }),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Products added successfully!')),
        );
        // Refresh the product list to show the new items
        await fetchProducts(widget.userId);
        // Load saved checkbox states after refreshing products
        await _loadCheckboxStates();

        // Clear the text fields and close the dialog
        setState(() {
          localControllers = [
            {'productName': TextEditingController()}
          ]; // Reset for next time
        });
      } else {
        // Handle server errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add products: ${response.body}')),
        );
      }
    } catch (e) {
      // Handle network or other errors
      print('Error adding new products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  // ## NEW ##: Function to save updated product names (Edit mode)
  Future<void> updateProducts({List<Map<String, dynamic>>? products}) async {
    // Use the provided products list or build from _productControllers (edit mode)
    final updatedProducts = products ??
        _productControllers
            .map((controller) => controller.text.trim())
            .where((name) => name.isNotEmpty)
            .map((name) => {'productName': name})
            .toList();

    try {
      final response = await http.post(
        Uri.parse('${server}userdetails/products/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': widget.id,
          'updatedProducts': updatedProducts,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved changes!')),
        );
        setState(() {
          isEditing = false;
        });
        await fetchProducts(widget.userId); // refresh
        // Load saved checkbox states after updating products
        await _loadCheckboxStates();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error updating products: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  // ## NEW ##: Function to delete products
  Future<void> deleteProducts(
      List<Map<String, dynamic>> remainingProducts) async {
    try {
      final response = await http.post(
        Uri.parse('${server}userdetails/products/delete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': widget.id,
          'remainingProducts': remainingProducts,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Products deleted successfully!')),
        );
        // Refresh the product list to show the updated items
        await fetchProducts(widget.userId);
        // Load saved checkbox states after refreshing products
        await _loadCheckboxStates();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete products: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error deleting products: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('An error occurred while deleting. Please try again.')),
      );
    }
  }

  Widget buildInfoRow(
      String? value, TextEditingController controller, bool isEditing) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 15,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 10),
                isEditing
                    ? Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            // hintText: placeholder,
                            hintStyle: TextStyle(color: Colors.grey),
                            // labelText: placeholder,
                            // labelStyle: TextStyle(color: Colors.grey),
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
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8.0),
                          ),
                        ),
                      )
                    : Text(
                        value ?? 'Loading...',
                        style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ],
            ),
          ),
          SizedBox(height: 15),
          Divider(color: Colors.grey),
          SizedBox(height: 15),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          (() {
            for (var product in allproductList) {
              if (product['id'] == widget.id) {
                return product['title'] ?? 'No title found';
              }
            }
            return 'No title found'; // default if no match
          })(),
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Reset all checkboxes button (for testing)
          // if (checked)
          IconButton(
            icon: Icon(Icons.refresh,
                color: const Color.fromARGB(255, 39, 39, 39)),
            onPressed: _resetAllCheckboxes,
            tooltip: 'Reset all checkboxes',
          ),
          if (_selectedIndexes.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: Text('Delete selected'),
                    content: Text('Delete the selected products ?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          )),
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          )),
                    ],
                  ),
                );

                if (shouldDelete != true) return;

                try {
                  // Find the current product data for this specific widget
                  final currentProductData = allproductList.firstWhere(
                    (product) => product['id'] == widget.id,
                    orElse: () => {},
                  );

                  if (!validateProductData(currentProductData)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invalid product data')),
                    );
                    return;
                  }

                  // Safely copy and filter the list:
                  final currentList = getParsedProducts(currentProductData);
                  if (currentList.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No products to delete')),
                    );
                    return;
                  }

                  print(
                      'Deleting from product ID ${widget.id}: ${currentList.length} total products, ${_selectedIndexes.length} selected for deletion');

                  // Validate that all selected indexes are within range
                  final invalidIndexes = _selectedIndexes
                      .where((index) => index >= currentList.length)
                      .toList();
                  if (invalidIndexes.isNotEmpty) {
                    print('Warning: Invalid indexes found: $invalidIndexes');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Invalid selection detected. Please try again.')),
                    );
                    return;
                  }

                  final newList = currentList
                      .asMap()
                      .entries
                      .where((entry) => !_selectedIndexes.contains(entry.key))
                      .map((entry) => entry.value)
                      .toList();

                  print('After deletion: ${newList.length} products remaining');

                  setState(() {
                    _selectedIndexes.clear();
                  });

                  await deleteProducts(newList);

                  // Show success message
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   SnackBar(content: Text('Products deleted successfully')),
                  // );
                } catch (e) {
                  print('Error during deletion: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting products: $e')),
                  );
                }
              },
            ),
        ],
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Container(
                height: 2.5,
                color: Colors.grey,
              ),
              for (var allProducts in allproductList)
                if (allProducts['id'] == widget.id)
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Listed Items:',
                              style: TextStyle(
                                fontFamily: 'Times New Roman',
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 165, 130, 14),
                                fontSize: 18,
                              ),
                            ),

                            //Stttt
                            Row(
                              children: [
                                !isEditing
                                    ? IconButton(
                                        onPressed: () {
                                          setState(() {
                                            isEditing = true;
                                            _productControllers = getParsedProducts(
                                                    allProducts)
                                                .map<TextEditingController>(
                                                    (p) => TextEditingController(
                                                        text:
                                                            p['productName'] ??
                                                                ''))
                                                .toList();
                                          });
                                        },
                                        icon: Icon(
                                          Icons.edit,
                                          color:
                                              Color.fromARGB(255, 165, 130, 14),
                                        ),
                                        tooltip: 'Edit products',
                                      )
                                    : Row(
                                        children: [
                                          IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  isEditing = false;
                                                });
                                                // Navigator.of(context).pop();
                                              },
                                              icon: Icon(
                                                Icons.cancel,
                                                color: Colors.red,
                                              )),
                                          IconButton(
                                              onPressed: updateProducts,
                                              icon: Icon(
                                                Icons.save,
                                                color: Colors.green,
                                              )),
                                        ],
                                      ),
                                IconButton(
                                  onPressed: () {
                                    final parsedProducts =
                                        getParsedProducts(allProducts);
                                    if (parsedProducts.isNotEmpty) {
                                      // Filter products where checkbox is NOT checked (false)
                                      final uncheckedProducts = parsedProducts
                                          .asMap()
                                          .entries
                                          .where((entry) {
                                        int index = entry.key;
                                        return index < _isChecked.length &&
                                            _isChecked[index] ==
                                                false; // only unchecked
                                      }).toList();

                                      if (uncheckedProducts.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'No unchecked products to copy')),
                                        );
                                        return;
                                      }
                                      // Build the string with unchecked items only
                                      final textToCopy =
                                          uncheckedProducts.map((entry) {
                                        int index = entry.key;
                                        var product = entry.value;
                                        return '${index + 1}. ${product['productName']}';
                                      }).join('\n');

                                      Clipboard.setData(
                                          ClipboardData(text: textToCopy));

                                      // Show share button after copying
                                      setState(() {
                                        copiedText = textToCopy;
                                        showShareButton = true;
                                      });

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Copied to clipboard!'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );

                                      // Hide share button after 10 seconds
                                      Future.delayed(Duration(seconds: 10), () {
                                        if (mounted) {
                                          setState(() {
                                            showShareButton = false;
                                          });
                                        }
                                      });
                                    }
                                  },
                                  icon: Icon(
                                    Icons.copy,
                                    color: Color.fromARGB(255, 165, 130, 14),
                                  ),
                                  tooltip: 'Copy unchecked products',
                                ),
                                if (showShareButton)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () async {
                                          try {
                                            await Share.share(copiedText);
                                          } catch (e) {
                                            // Fallback: Copy to clipboard again and show message
                                            await Clipboard.setData(
                                                ClipboardData(
                                                    text: copiedText));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Copied to clipboard again! Share manually.'),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                          }
                                        },
                                        icon: Icon(
                                          Icons.share,
                                          color: Colors.blue,
                                        ),
                                        tooltip: 'Share copied text',
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            showShareButton = false;
                                          });
                                        },
                                        icon: Icon(
                                          Icons.close,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        tooltip: 'Hide share button',
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        ...getParsedProducts(allProducts)
                            .asMap()
                            .entries
                            .map<Widget>((entry) {
                          int index = entry.key;
                          var product = entry.value;

                          if (isEditing) {
                            // EDIT MODE: same as before
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 9.0),
                              child: TextField(
                                controller: _productControllers[index],
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                        color: Colors.grey, width: 2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 8.0),
                                  labelText: 'Product ${index + 1}',
                                  labelStyle: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  // border: OutlineInputBorder(),
                                ),
                              ),
                            );
                          } else {
                            bool isSelected = _selectedIndexes.contains(index);

                            return GestureDetector(
                              onLongPress: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedIndexes.remove(index);
                                  } else {
                                    _selectedIndexes.add(index);
                                  }
                                });
                              },
                              child: Container(
                                color: isSelected
                                    ? Colors.grey.shade300
                                    : Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${index + 1}. ${product['productName']}',
                                              style: TextStyle(
                                                fontFamily: 'Times New Roman',
                                                color: (index <
                                                            _isChecked.length &&
                                                        _isChecked[index])
                                                    ? Colors.grey
                                                    : Colors.black,
                                                fontSize: 18,
                                                decoration: (index <
                                                            _isChecked.length &&
                                                        _isChecked[index])
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none,
                                              ),
                                            ),
                                          ),
                                          Checkbox(
                                            value: index < _isChecked.length
                                                ? _isChecked[index]
                                                : false,
                                            activeColor: Colors.grey,
                                            checkColor: Colors.white,
                                            onChanged: (bool? value) async {
                                              if (index < _isChecked.length) {
                                                setState(() {
                                                  _isChecked[index] =
                                                      value ?? false;
                                                  // checked = true;
                                                });
                                                // Save the updated checkbox state
                                                await _saveCheckboxStates();
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          }
                        }),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [],
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
          // ## STYLE ADDED HERE ##
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 71, 71, 71),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            // Optional: Add some padding for better spacing
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () {
            final formKey = GlobalKey<FormState>();
            final List<Map<String, TextEditingController>> dialogControllers = [
              {'productName': TextEditingController()}
            ];

            void disposeAllControllers() {
              for (var controllerMap in dialogControllers) {
                controllerMap['productName']?.clear();
              }
            }

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    void addProductField() {
                      setDialogState(() {
                        dialogControllers
                            .add({'productName': TextEditingController()});
                      });
                    }

                    void removeProductField() {
                      if (dialogControllers.length > 1) {
                        setDialogState(() {
                          dialogControllers.last['productName']?.dispose();
                          dialogControllers.removeLast();
                        });
                      }
                    }

                    return AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      title: Center(child: Text('Add New Products')),
                      content: Form(
                        key: formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...List.generate(dialogControllers.length,
                                  (index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: TextFormField(
                                    controller: dialogControllers[index]
                                        ['productName'],
                                    decoration: InputDecoration(
                                      labelText: 'Product ${index + 1}',
                                      labelStyle: TextStyle(
                                        color: Color.fromARGB(255, 105, 105,
                                            105), // blueGrey replaced with medium grey
                                        fontWeight: FontWeight.w600,
                                      ),
                                      prefixIcon: Icon(Icons.shopping_bag,
                                          color: Color.fromARGB(
                                              255, 128, 128, 128)), // grey icon
                                      filled: true,
                                      fillColor: Color.fromARGB(255, 253, 253,
                                          253), // very light grey background
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 16.0, horizontal: 20.0),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        borderSide: BorderSide(
                                            color: Color.fromARGB(255, 190, 189,
                                                190)), // medium grey border
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        borderSide: BorderSide(
                                            color: Color.fromARGB(
                                                255, 120, 120, 120),
                                            width: 2.0), // darker grey on focus
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        borderSide: BorderSide(
                                            color: Colors.redAccent,
                                            width: 2.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        borderSide: BorderSide(
                                            color: Colors.redAccent,
                                            width: 2.0),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (index == 0 &&
                                          (value == null || value.isEmpty)) {
                                        return 'Please enter at least one product';
                                      }
                                      return null;
                                    },
                                  ),
                                );
                              }),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.add_circle,
                                        color: const Color.fromARGB(
                                            255, 53, 53, 53),
                                        size: 30),
                                    onPressed: addProductField,
                                    tooltip: 'Add another product',
                                  ),
                                  if (dialogControllers.length > 1)
                                    IconButton(
                                      icon: Icon(Icons.remove_circle,
                                          color:
                                              Color.fromARGB(255, 53, 53, 53),
                                          size: 30),
                                      onPressed: removeProductField,
                                      tooltip: 'Remove last product',
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            disposeAllControllers();
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              final List<String> newNames = [];
                              for (final controllerMap in dialogControllers) {
                                final controller = controllerMap['productName'];
                                if (controller != null &&
                                    controller.text.trim().isNotEmpty) {
                                  newNames.add(controller.text.trim());
                                }
                              }

                              if (newNames.isNotEmpty) {
                                addNewProducts(newNames);
                                disposeAllControllers();
                                // Navigator.of(context).pop();
                              } else {}
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
          child: Row(
            mainAxisSize:
                MainAxisSize.min, // Prevents the button from stretching
            children: [
              Text('Add more products'),
              SizedBox(width: 8), // Add a little space between text and icon
              Icon(Icons.add),
            ],
          ),
        ),
      ),
    );
  }
}
