import 'package:basic_utils/basic_utils.dart';
import 'package:caspian/safepool/safepool.dart';
import 'package:flutter/material.dart';

import '../navigation/bar.dart';

var appsIcons = {
  "chat": Icons.chat,
  "library": Icons.folder,
  "invite": Icons.token,
};

class Pool extends StatelessWidget {
  const Pool({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final poolName = ModalRoute.of(context)!.settings.arguments as String;
    var pool = poolGet(poolName);
    var apps = pool.apps;
    var appsWidgets = apps.fold(<Widget>[], (res, e) {
      res.addAll([
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/apps/$e", arguments: poolName);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(height: 20),
                    Icon(appsIcons[e]),
                    const SizedBox(height: 10),
                    Text(StringUtils.capitalize(e)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ]);
      return res;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(poolName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: appsWidgets,
        ),
      ),
      bottomNavigationBar: MainNavigationBar(poolName),
    );
  }
}
