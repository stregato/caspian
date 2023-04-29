import 'dart:isolate';

import 'package:caspian/common/progress.dart';
import 'package:caspian/pool/addstorage.dart';
import 'package:caspian/safepool/safepool.dart' as sp;
import 'package:caspian/safepool/safepool_def.dart' as sp;
import 'package:flutter/material.dart';
import 'package:basic_utils/basic_utils.dart';

class CreatePool extends StatefulWidget {
  const CreatePool({super.key});

  @override
  State<CreatePool> createState() => _CreatePoolState();
}

const urlHint = "Enter a supported URL and click +";
const validSchemas = ["s3", "sftp", "file"];
const availableApps = ["chat", "library", "gallery"];

class _CreatePoolState extends State<CreatePool> {
  final _formKey = GlobalKey<FormState>();

  final _config = sp.Config();
  final _appsMap = {for (var e in availableApps) e: true};

  bool _validConfig() {
    var apps = [];
    _appsMap.forEach((key, value) {
      if (value) apps.add(key);
    });

    return _config.name != "" && _config.public_.isNotEmpty && apps.isNotEmpty;
  }

  static _poolCreate(sp.Config config, List<String> apps) =>
      Isolate.run(() => sp.poolCreate(config, apps));

  @override
  Widget build(BuildContext context) {
    var appsList = availableApps
        .map((e) => CheckboxListTile(
            title: Text(StringUtils.capitalize(e)),
            value: _appsMap[e],
            onChanged: (a) {
              setState(() {
                _appsMap[e] = !(_appsMap[e] ?? false);
              });
            }))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Pool"),
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
                const Text(
                    "Enter a name and at least a public storage, i.e. sftp or s3"),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    return null;
                  },
                  onChanged: (val) => setState(() => _config.name = val),
                ),
                Row(
                  children: [
                    const Text(
                      "Storages",
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                                builder: (context) => const AddStorage()))
                            .then((value) {
                          if (value is Storage) {
                            setState(() {
                              if (value.public) {
                                _config.public_.add(value.url);
                              } else {
                                _config.private_.add(value.url);
                              }
                            });
                          }
                        });
                      },
                      icon: const Icon(Icons.add),
                    )
                  ],
                ),
                ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: _config.public_.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: const Icon(Icons.share),
                    trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _config.public_.removeAt(index);
                          });
                        }),
                    title: Text(_config.public_[index]),
                  ),
                ),
                ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: _config.private_.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: const Icon(Icons.person),
                    trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _config.private_.removeAt(index);
                          });
                        }),
                    title: Text(_config.private_[index]),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  "Services",
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                Column(children: appsList),
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: _validConfig()
                        ? () async {
                            List<String> apps = [];
                            _appsMap.forEach((key, value) {
                              if (value) apps.add(key);
                            });
                            await progressDialog(
                                context,
                                "filling the pool, please wait",
                                _poolCreate(_config, apps),
                                successMessage:
                                    "Congrats! You successfully created ${_config.name}",
                                errorMessage: "Creation failed");
                          }
                        : null,
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
