import 'dart:io';

import 'package:caspian/navigation/bar.dart';
import 'package:caspian/safepool/safepool.dart' as sp;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class Invite extends StatefulWidget {
  const Invite({super.key});

  @override
  State<Invite> createState() => _InviteState();
}

class _InviteState extends State<Invite> {
  final _formKey = GlobalKey<FormState>();

  String _token = "";
  final List<String> _ids = [];

  @override
  Widget build(BuildContext context) {
    final poolName = ModalRoute.of(context)!.settings.arguments as String;
    var idController = TextEditingController();

    Widget shareButton;
    if (Platform.isAndroid || Platform.isIOS) {
      shareButton = ElevatedButton.icon(
          icon: const Icon(Icons.share),
          label: const Text("Share"),
          onPressed: _token.isNotEmpty
              ? () {
                  final box = context.findRenderObject() as RenderBox?;
                  Share.share(_token,
                      subject: "Invite to $poolName",
                      sharePositionOrigin:
                          box!.localToGlobal(Offset.zero) & box.size);
                }
              : null);
    } else {
      shareButton = ElevatedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text("Copy to the clipboard"),
          onPressed: _token.isNotEmpty
              ? () {
                  Clipboard.setData(ClipboardData(text: _token)).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Id copied to clipboard")));
                  });
                }
              : null);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Create a Invite"),
        actions: [
          ElevatedButton.icon(
            label: const Text("Received"),
            onPressed: () {},
            icon: const Icon(Icons.list),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              ListView(
                shrinkWrap: true,
                children: _ids
                    .map(
                      (id) => Card(
                        child: ListTile(
                          title: Text(id),
                          trailing: IconButton(
                            onPressed: () {
                              setState(() {
                                _ids.remove(id);
                              });
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              Builder(
                builder: (context) => Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        maxLines: 2,
                        controller: idController,
                        decoration: InputDecoration(
                          labelText: 'Enter the id',
                          suffixIcon: IconButton(
                            onPressed: () {
                              if (idController.text.isNotEmpty) {
                                setState(() {
                                  _ids.add(idController.text);
                                  idController.clear();
                                });
                              }
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.length == 88) {
                            try {
                              sp.securityIdentityFromId(value);
                              setState(() {
                                _ids.add(value);
                                idController.clear();
                              });
                            } catch (e) {
                              //invalid id
                            }
                          }
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 16.0),
                        child: ElevatedButton(
                          onPressed: _ids.isNotEmpty
                              ? () {
                                  setState(() {
                                    try {
                                      _token =
                                          sp.poolInvite(poolName, _ids, "");
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                        "Share the token with your peers",
                                      )));
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              backgroundColor: Colors.red,
                                              content: Text(
                                                "Generation failsed: $e",
                                              )));
                                    }
                                  });
                                }
                              : null,
                          child: const Text('Create'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("Invite for $poolName"),
              const SizedBox(
                height: 4,
              ),
              Text(
                  _token.length < 128
                      ? _token
                      : "${_token.substring(0, 128)}...",
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 20),
              shareButton,
            ],
          ),
        ),
      ),
      bottomNavigationBar: MainNavigationBar(poolName),
    );
  }
}
