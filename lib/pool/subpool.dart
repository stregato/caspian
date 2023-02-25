import 'package:caspian/safepool/safepool.dart' as sp;
import 'package:caspian/safepool/safepool_def.dart' as sp;
import 'package:flutter/material.dart';
import 'package:basic_utils/basic_utils.dart';

class SubPool extends StatefulWidget {
  const SubPool({super.key});

  @override
  State<SubPool> createState() => _SubPoolState();
}

const urlHint = "Enter a supported URL and click +";
const validSchemas = ["s3", "sftp", "file"];
const availableApps = ["chat", "library", "gallery"];

class _SubPoolState extends State<SubPool> {
  final _formKey = GlobalKey<FormState>();

  late Map<String, bool> _apps;
  late Map<sp.Identity, bool> _ids;
  String _poolName = "";
  String _sub = "";

  @override
  Widget build(BuildContext context) {
    final poolName = ModalRoute.of(context)!.settings.arguments as String;

    if (_poolName == "") {
      _poolName = poolName;
      var pool = sp.poolGet(poolName);
      var selfId = sp.getSelfId();
      _apps = {for (var e in pool.apps) e: true};
      _ids = {for (var i in sp.poolUsers(poolName)) i: i.id() == selfId};
    }

    var appsList = _apps.entries
        .map((e) => CheckboxListTile(
            title: Text(StringUtils.capitalize(e.key)),
            value: e.value,
            onChanged: (a) {
              setState(() {
                _apps[e.key] = !e.value;
              });
            }))
        .toList();

    var idsList = _ids.entries
        .map((e) => CheckboxListTile(
            title: Text(e.key.nick.isNotEmpty ? e.key.nick : e.key.id()),
            value: e.value,
            onChanged: (a) {
              setState(() {
                _ids[e.key] = !e.value;
              });
            }))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Sub-Pool"),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Builder(
          builder: (context) => Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Enter the subpool name"),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    return null;
                  },
                  onChanged: (val) => setState(() => _sub = val),
                ),
                const SizedBox(height: 10),
                ListView(shrinkWrap: true, children: [
                  const Text("Apps",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ...appsList
                ]),
                const SizedBox(height: 10),
                ListView(shrinkWrap: true, children: [
                  const Text("Users",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ...idsList
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      var apps = _apps.entries
                          .where((e) => e.value)
                          .map((e) => e.key)
                          .toList();
                      var ids = _ids.entries
                          .where((e) => e.value)
                          .map((e) => e.key.id())
                          .toList();

                      try {
                        sp.poolSub(_poolName, _sub, ids, apps);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                          "Congrats! You successfully created $_sub",
                        )));
                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              "Creation failed: $e",
                            )));
                      }
                    },
                    child: const Text('Create'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
