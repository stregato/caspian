import 'dart:async';
import 'dart:isolate';

import 'package:caspian/common/const.dart';
import 'package:caspian/common/progress.dart';
import 'package:caspian/navigation/bar.dart';
import 'package:caspian/safepool/safepool.dart' as sp;
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'package:flutter/services.dart' show PlatformException;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static StreamSubscription<Uri?>? linkSub;
  Uri? _unilink;

  @override
  void initState() {
    super.initState();
    if (!isDesktop && linkSub == null) {
      try {
        getInitialUri().then((uri) {
          _unilink = uri;
          linkSub = uriLinkStream.listen((uri) => setState(() {
                _unilink = uri;
              }));
        });
      } on PlatformException {
        //platform does not support
      }
    }
  }

  void _processUnilink(BuildContext context) {
    if (_unilink == null) {
      return;
    }

    setState(() {
      var segments = _unilink!.pathSegments;
      switch (segments[0]) {
        case "invite":
          if (segments.length == 2) {
            var token = Uri.decodeComponent(segments[1]);
            Future.delayed(
                const Duration(milliseconds: 100),
                () => Navigator.pushNamed(context, "/addPool/import",
                    arguments: token));
          }
          break;
        case "id":
          break;
      }
      _unilink = null;
    });
  }

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
    _processUnilink(context);

    var poolList = sp.poolList();
    var widgets = poolList.map(
      (e) {
        var parts = e.split("/");
        String name;
        String sub;
        if (parts.length > 1 && parts.last.startsWith('#')) {
          name = parts.sublist(0, parts.length - 1).join('/');
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
