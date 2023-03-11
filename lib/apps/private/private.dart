import 'package:caspian/apps/chat/chat.dart';
import 'package:caspian/apps/private/add_private.dart';
import 'package:caspian/navigation/bar.dart';
import 'package:flutter/material.dart';
import 'package:caspian/safepool/safepool.dart' as sp;
import 'package:caspian/safepool/safepool_def.dart' as sp;

class Private extends StatelessWidget {
  const Private({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final poolName = ModalRoute.of(context)!.settings.arguments as String;

    Map<String, String> id2nick = {};
    for (var user in sp.poolUsers(poolName)) {
      id2nick[user.id()] = user.nick;
    }

    var privates = sp.chatPrivates(poolName);
    var privateButtons = privates.map((pr) {
      var nicks = pr.map((e) => id2nick[e] ?? e).toList();
      nicks.sort();
      var chips = nicks.map((e) {
        return Chip(
          avatar: CircleAvatar(
            backgroundColor: Colors.grey.shade800,
            child: Text(e.substring(0, 1)),
          ),
          label: Text(e),
        );
      }).toList();
      return ElevatedButton(
        onPressed: () {
          Navigator.pushNamed<sp.ChatPrivate>(context, "/apps/chat",
              arguments: ChatArgs(poolName, pr));
        },
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Wrap(
            spacing: 10,
            children: chips,
          ),
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(poolName),
        actions: [
          ElevatedButton.icon(
            label: const Text("Add"),
            onPressed: () async {
              var private = await Navigator.push<sp.ChatPrivate>(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AddPrivate(poolName)));
              if (private != null && context.mounted) {
                private.add(sp.securitySelfId());
                Navigator.pushNamed(context, "/apps/chat",
                    arguments: ChatArgs(poolName, private));
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: privateButtons,
        ),
      ),
      bottomNavigationBar: MainNavigationBar(poolName),
    );
  }
}
