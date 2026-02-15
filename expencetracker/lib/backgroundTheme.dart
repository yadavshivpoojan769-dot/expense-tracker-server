import 'package:flutter/material.dart';

class Backgroundtheme extends StatefulWidget {
  const Backgroundtheme({super.key});

  @override
  State<Backgroundtheme> createState() => _BackgroundthemeState();
}

class _BackgroundthemeState extends State<Backgroundtheme> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gradient banner (Container 1)
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue, Colors.purple],
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Gradient Header',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Show Dialog Button
            ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    backgroundColor:
                        Colors.transparent, // Make dialog itself transparent
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.6,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue, Colors.purple],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Form(
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        decoration: const InputDecoration(
                                          labelText: 'Title',
                                          labelStyle: TextStyle(
                                            fontFamily: 'Times New Roman',
                                            color: Colors.white,
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.white),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.white),
                                          ),
                                        ),
                                        style: const TextStyle(
                                          fontFamily: 'Times New Roman',
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      // Add more fields here if needed
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Close'),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: () {
                                  // Add logic here
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              child: const Text("Show Dialog"),
            ),
          ],
        ),
      ),
    );
  }
}
