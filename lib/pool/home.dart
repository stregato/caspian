import 'dart:io';
import 'dart:isolate';

import 'package:caspian/common/progress.dart';
import 'package:caspian/navigation/bar.dart';
import 'package:caspian/safepool/safepool.dart' as sp;
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

void waitDialog<T>(
    BuildContext context, String message, String error, Function f,
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
                Text(message)
              ],
            ),
          ),
        );
      });
  try {
    await Isolate.run(f());
    if (!mounted) return null;
    Navigator.of(context).pop();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(error)));
    Navigator.of(context).pop();
  }
  return null;
}

class _HomeState extends State<Home> {
  Future<Object?> openPool(BuildContext context, String pool,
      [bool mounted = true]) async {
    var p =
        await progressDialog(context, "Connecting to $pool...", Isolate.run(() {
      return sp.poolGet(pool);
    }), errorMessage: "cannot connect to %s");
    if (p != null && context.mounted) {
      return Navigator.pushNamed(context, "/pool", arguments: pool);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    var poolList = sp.poolList();
    var widgets = poolList.map(
      (e) {
        var parts = e.split("/");
        String name;
        String sub;
        if (parts.length > 2 && parts[parts.length - 2] == '@') {
          name = parts.sublist(0, parts.length - 2).join('/');
          sub = parts.last;
        } else {
          name = e;
          sub = "";
        }
        return Card(
          child: ListTile(
            title: Text(name),
            subtitle: sub.isNotEmpty ? Text(sub) : null,
            leading: sub.isEmpty
                ? const Icon(Icons.waves)
                : const Icon(Icons.child_care),
            onTap: () => openPool(context, e).then((value) {
              setState(() {});
            }),
          ),
        );
      },
    ).toList();

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
      bottomNavigationBar: const MainNavigationBar(null),
    );
  }
}
