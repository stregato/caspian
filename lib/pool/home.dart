import 'dart:isolate';

import 'package:caspian/safepool/safepool.dart';
import 'package:flutter/material.dart';

import '../common/main_navigation_bar.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  void openPool(BuildContext context, String pool,
      [bool mounted = true]) async {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) {
          return Dialog(
            // The background color
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The loading indicator
                  const CircularProgressIndicator(),
                  const SizedBox(
                    height: 15,
                  ),
                  // Some text
                  Text("Connecting to pool $pool...")
                ],
              ),
            ),
          );
        });
    await Isolate.run(() {
      getPool(pool);
    });
    if (!mounted) return;
    Navigator.of(context).pop();
    Navigator.pushNamed(context, "/pool", arguments: pool);
  }

  @override
  Widget build(BuildContext context) {
    var poolList = getPoolList();
    var widgets = poolList
        .map(
          (e) => Card(
            child: ListTile(
              title: Text(e),
              leading: const Icon(Icons.waves),
              onTap: () => openPool(context, e),
            ),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your pools"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, "/addPool")
                      .then((value) => {setState(() {})});
                },
                child: const Icon(
                  Icons.add,
                )),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: widgets,
      ),
      bottomNavigationBar: const MainNavigatorBar(),
    );
  }
}
