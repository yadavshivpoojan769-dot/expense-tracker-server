import 'package:flutter/material.dart';

class Firstpage extends StatefulWidget {
  const Firstpage({super.key});

  @override
  State<Firstpage> createState() => _FirstpageState();
}

class _FirstpageState extends State<Firstpage> {
  bool isSelected = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  //Container 1
                  Container(
                    width: MediaQuery.of(context).size.width * 3,
                    height: MediaQuery.of(context).size.height * 0.33,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      // borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  //Container 2
                  Positioned(
                    top: -270,
                    left: -50,
                    child: Container(
                      width: 500, // Must be square for a perfect circle
                      height: 500,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue,
                            Colors.purple,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 150,
                    right: 130,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(
                        'https://www.pngall.com/wp-content/uploads/5/User-Profile-PNG-Download-Image.png',
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onLongPress: () {
                  setState(() {
                    isSelected = !isSelected; // toggle selection
                  });
                },
                onTap: () {
                  if (isSelected) {
                    // Delete confirmation
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Delete Transaction?'),
                        content:
                            Text('Are you sure you want to delete this entry?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                // ✅ perform deletion
                                // call your delete function here
                                // example: deleteTransaction(budgetTransactions['id']);
                              });
                              Navigator.of(ctx).pop();
                            },
                            child: Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          child: Container(
                              // your existing dialog code here...
                              ),
                        );
                      },
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? Border.all(color: Colors.redAccent, width: 3)
                        : Border.all(color: Colors.transparent),
                  ),
                  child: ElevatedButton(
                    onPressed: null, // disable built-in onPressed
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
                          colors: isSelected
                              ? [Colors.red.shade300, Colors.red.shade800]
                              : [Colors.blue, Colors.purple],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                          vertical: MediaQuery.of(context).size.width * 0.03,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Date:',
                                  style: TextStyle(color: Colors.white),
                                )
                              ],
                            ),
                            Text(
                              'Title:',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Times New Roman',
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )),
        ));
  }
}
