import 'package:expencetracker/budget.dart';
import 'package:expencetracker/homepage.dart';
import 'package:expencetracker/listProduct.dart';
import 'package:expencetracker/profile.dart';
import 'package:expencetracker/searchBar.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  final int currentIndex;
  final String userEmail;

  const MainPage(
      {super.key, required this.currentIndex, required this.userEmail});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      Homepage(userEmail: widget.userEmail),
      Searchbar(userEmail: widget.userEmail),
      Budget(userEmail: widget.userEmail),
      // Shop(userEmail: widget.userEmail),
      Listproduct(userEmail: widget.userEmail),
      // Placeholder(),
      // Placeholder(),
      Profile(userEmail: widget.userEmail),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color.fromARGB(255, 0, 110, 201),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.currency_rupee_sharp), label: 'Budget'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'List'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
