import 'dart:io';

import 'package:caspian/safepool/safepool.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class ImportPool extends StatefulWidget {
  const ImportPool({super.key});

  @override
  State<ImportPool> createState() => _ImportPoolState();
}

class _ImportPoolState extends State<ImportPool> {
  final _formKey = GlobalKey<FormState>();

  String? _token;
  late String _title;
  String? _validateMessage;
  bool _validToken = false;

  void _updateToken(String? value) {
    _token = value;
    try {
      var i = poolParseInvite(_token!);
      if (i.config != null) {
        _validateMessage = i.subject == ""
            ? "Invite to ${i.config?.name} by ${i.sender.nick}"
            : "Invite to ${i.config?.name} by ${i.sender.nick}: ${i.subject}";
        _validToken = true;
        _title = "Join ${i.config?.name}";
      } else {
        _validateMessage = "Invite by ${i.sender.nick} is not for you";
        _validToken = false;
        _title = "Join a Pool";
      }
    } catch (e) {
      _validateMessage = "invalid token: $e";
      _validToken = false;
      _title = "Join a Pool";
    }
  }

  @override
  Widget build(BuildContext context) {
    var selfId = securitySelfId();

    _token ??= ModalRoute.of(context)?.settings.arguments as String?;
    _updateToken(_token);

    Widget shareButton;
    if (Platform.isAndroid || Platform.isIOS) {
      shareButton = ElevatedButton.icon(
          icon: const Icon(Icons.share),
          label: const Text("Share the id"),
          onPressed: () {
            final box = context.findRenderObject() as RenderBox?;
            Share.share(selfId,
                subject: "Can you add me to your pool?",
                sharePositionOrigin:
                    box!.localToGlobal(Offset.zero) & box.size);
          });
    } else {
      shareButton = ElevatedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text("Copy id to the clipboard"),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: selfId)).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Id copied to clipboard")));
            });
          });
    }

    var shareIdSection = <Widget>[
      const Text("The below text is your global id. Share the id with a "
          "peer in the pool to get an invite token."),
      const Text("Your peer will provide you an invite. Add it in the "
          "input below and click Import"),
      const SizedBox(height: 20),
      Text(selfId,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
          )),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          shareButton,
          ElevatedButton(
              child: const Text("Continue"),
              onPressed: () {
                Share.share(selfId, subject: "Can you add me to your pool?");
              }),
        ],
      ),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(_title),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Column(
          children: [
            if (!_validToken) ...shareIdSection,
            const SizedBox(height: 20),
            Builder(
              builder: (context) => Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      initialValue: _token,
                      maxLines: 6,
                      decoration:
                          const InputDecoration(labelText: 'Invite Token'),
                      validator: (value) => _validateMessage,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (val) => setState(() => _updateToken(val)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 16.0),
                      child: ElevatedButton(
                        onPressed: _validToken
                            ? () {
                                try {
                                  var config = poolJoin(_token!);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          content: Text(
                                    "Congrats! You successfully joined ${config.name}",
                                  )));
                                  Navigator.pop(context);
                                } catch (e) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          backgroundColor: Colors.red,
                                          content: Text(
                                            "Invalid token: $e",
                                          )));
                                }
                              }
                            : null,
                        child: const Text('Join'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
