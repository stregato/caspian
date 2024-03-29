import 'dart:io';

//import 'package:file_selector/file_selector.dart';
import 'package:caspian/common/image.dart';
import 'package:flutter/material.dart';
import 'package:caspian/navigation/bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:caspian/safepool/safepool.dart' as sp;
import 'package:flutter/services.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  static String _logLevel = "Error";

  int _fullReset = 5;
  late Uint8List _avatar;

  _selectAvatar() async {
    XFile? xfile = await pickImage();
    if (xfile == null) return;

    var bytes = await xfile.readAsBytes();
    setState(() {
      _avatar = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ButtonStyle(
      padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.all(14)),
    );

    final logLevels = {
      "Fatal": 1,
      "Error": 2,
      "Info": 4,
      "Debug": 5,
      "Trace": 6,
    };

    var self = sp.securityGetSelf();
    var nick = TextEditingController(text: self.nick);
    var email = TextEditingController(text: self.email);
    _avatar = self.avatar;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Your nick'),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      controller: nick,
                    ),
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Your email'),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      controller: email,
                    ),
                  ]),
                ),
                const SizedBox(
                  width: 8,
                ),
                InkWell(
                  onTap: _selectAvatar,
                  child: Image.memory(
                    _avatar,
                    width: 128,
                  ),
                )
              ],
            ),
            ElevatedButton.icon(
                style: buttonStyle,
                label: const Text("Update"),
                icon: const Icon(Icons.save),
                onPressed: () {
                  self.avatar = _avatar;
                  self.nick = nick.text;
                  self.email = email.text;
                  sp.securitySetSelf(self);
                }),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: buttonStyle,
                    label: const Text('Export Identity'),
                    icon: const Icon(Icons.download),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: buttonStyle,
                    label: const Text('Import Identity'),
                    icon: const Icon(Icons.upload),
                    onPressed: () {
                      try {
                        var logs = sp.logs();

                        if (Platform.isAndroid || Platform.isIOS) {
                          var file = XFile.fromData(
                              Uint8List.fromList(logs.codeUnits),
                              mimeType: "text/plain",
                              name: "safepool.log");
                          Share.shareXFiles([file],
                              subject: "Dump from Caspian");
                        } else {
                          // getSavePath(suggestedName: "safepool.log")
                          //     .then((value) {
                          //   File(value!).writeAsString(logs);
                          // });
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              "Cannot dump: $e",
                            )));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Danger Zone",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            DropdownButton(
                value: _logLevel,
                items: logLevels.keys
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (e) {
                  setState(() {
                    _logLevel = e!;
                    sp.setLogLevel(logLevels[_logLevel] ?? 1);
                  });
                }),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: buttonStyle,
                    label: const Text('Copy Logs'),
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      try {
                        var logs = sp.logs();
                        if (Platform.isAndroid || Platform.isIOS) {
                          Share.share(logs, subject: "Logs from Caspian");
                        } else {
                          Clipboard.setData(ClipboardData(text: logs))
                              .then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Copied to clipboard")));
                          });
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              "Cannot dump: $e",
                            )));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: buttonStyle,
                    label: const Text('Download Logs'),
                    icon: const Icon(Icons.download_for_offline),
                    onPressed: () {
                      try {
                        var logs = sp.logs();

                        if (Platform.isAndroid || Platform.isIOS) {
                          var file = XFile.fromData(
                              Uint8List.fromList(logs.codeUnits),
                              mimeType: "text/plain",
                              name: "safepool.log");
                          Share.shareXFiles([file],
                              subject: "Dump from Caspian");
                        } else {
                          // getSavePath(suggestedName: "safepool.log")
                          //     .then((value) {
                          //   File(value!).writeAsString(logs);
                          // });
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              "Cannot dump: $e",
                            )));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 14,
            ),
            ElevatedButton.icon(
                style: buttonStyle,
                label: Text("Factory Reset (click $_fullReset times)"),
                icon: const Icon(Icons.restore),
                onPressed: () => setState(() {
                      if (_fullReset == 0) {
                        sp.factoryReset();
                        _fullReset = 5;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                backgroundColor: Colors.green,
                                content:
                                    Text("Full Reset completed! Good luck")));
                        Navigator.popUntil(context, (route) => route.isFirst);
                      } else {
                        _fullReset--;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            backgroundColor: Colors.red,
                            duration: const Duration(milliseconds: 300),
                            content:
                                Text("$_fullReset clicks to factory reset!")));
                      }
                    })),
          ],
        ),
      ),
      bottomNavigationBar: const MainNavigationBar(null),
    );
  }
}
