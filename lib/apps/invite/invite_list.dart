import 'package:caspian/safepool/safepool.dart' as sp;
import 'package:flutter/material.dart';

class InviteList extends StatefulWidget {
  const InviteList({Key? key}) : super(key: key);

  @override
  State<InviteList> createState() => _InviteListState();
}

class _InviteListState extends State<InviteList> {
  @override
  Widget build(BuildContext context) {
    final poolName = ModalRoute.of(context)!.settings.arguments as String;

    var after = DateTime.now().subtract(const Duration(days: 30));
    var items = sp
        .inviteReceive(poolName, after, true)
        .map(
          (i) => Card(
            child: ListTile(
              title: Text("Invite from ${i.sender.nick} to join ${i.name}"),
              subtitle: i.subject.isNotEmpty ? Text(i.subject) : null,
              trailing: const Icon(Icons.join_full),
              onTap: () {},
            ),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Invites"),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(8),
            children: items,
          ),
        ),
      ),
    );
  }
}
