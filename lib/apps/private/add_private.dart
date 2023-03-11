import 'package:caspian/navigation/bar.dart';
import 'package:flutter/material.dart';
import 'package:caspian/safepool/safepool_def.dart' as sp;
import 'package:caspian/safepool/safepool.dart' as sp;

class AddPrivate extends StatefulWidget {
  final String poolName;
  const AddPrivate(this.poolName, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AddPrivateState();
}

class AddPrivateState extends State<AddPrivate> {
  final sp.ChatPrivate _selected = [];

  @override
  Widget build(BuildContext context) {
    var selfId = sp.securitySelfId();
    var selectedTiles = <Widget>[];
    for (var i in sp.poolUsers(widget.poolName)) {
      if (i.id() == selfId) {
        continue;
      }
      selectedTiles.add(CheckboxListTile(
          title: Text(i.nick),
          value: _selected.contains(i.id()),
          onChanged: (a) {
            setState(() {
              var id = i.id();
              if (_selected.contains(id)) {
                _selected.remove(id);
              } else {
                _selected.add(id);
              }
            });
          }));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.poolName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ListView(shrinkWrap: true, children: selectedTiles),
            ElevatedButton(
              onPressed: _selected.isNotEmpty
                  ? () => Navigator.pop(context, _selected)
                  : null,
              child: const Text('Create'),
            )
          ],
        ),
      ),
      bottomNavigationBar: MainNavigationBar(widget.poolName),
    );
  }
}
