import 'dart:io';

import 'package:caspian/navigation/bar.dart';
import 'package:caspian/safepool/safepool.dart' as sp;
import 'package:caspian/safepool/safepool_def.dart' as sp;
import 'package:flutter/material.dart';
import 'package:caspian/apps/chat/theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:caspian/common/file_access.dart';
import './download_file.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LibraryActions extends StatefulWidget {
  const LibraryActions({Key? key}) : super(key: key);

  @override
  State<LibraryActions> createState() => _LibraryActionsState();
}

class LibraryActionsArgs {
  String pool;
  sp.Document document;
  LibraryActionsArgs(this.pool, this.document);
}

class _LibraryActionsState extends State<LibraryActions> {
  AppTheme theme = LightTheme();

  String _appDir = "";

  @override
  void initState() {
    super.initState();
    getApplicationDocumentsDirectory().then((value) => _appDir = value.path);
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as LibraryActionsArgs;
    var d = args.document;

    String poolName = args.pool;
    Map<String, String> nicks = sp.poolUsers(poolName).fold({}, (m, i) {
      m[i.id()] = i.nick;
      return m;
    });

    var items = <Card>[];
    if (d.localPath.isNotEmpty) {
      items.add(
        Card(
          child: ListTile(
            title: const Text("Open Locally"),
            leading: const Icon(Icons.file_open),
            onTap: () => openFile(context, d.localPath),
          ),
        ),
      );
      if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
        items.add(
          Card(
            child: ListTile(
              title: const Text("Open Folder"),
              leading: const Icon(Icons.folder_open),
              onTap: () => openFile(context, File(d.localPath).parent.path),
            ),
          ),
        );
      } else {
        items.add(
          Card(
            child: ListTile(
              title: const Text("Share"),
              leading: const Icon(Icons.share),
              onTap: () {
                final box = context.findRenderObject() as RenderBox?;
                Share.shareXFiles([XFile(d.localPath)],
                    subject: "Can you add me to your pool?",
                    sharePositionOrigin:
                        box!.localToGlobal(Offset.zero) & box.size);
              },
            ),
          ),
        );
      }
      if (d.state == sp.DocumentState.modified ||
          d.state == sp.DocumentState.conflict) {
        items.add(
          Card(
            child: ListTile(
              title: const Text("Send update"),
              leading: const Icon(Icons.upload_file),
              onTap: () {
                try {
                  sp.librarySend(poolName, d.localPath, d.name, true, []);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(
                        "${d.name} uploaded to $poolName",
                      )));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(
                        "Cannot upload ${d.name}: $e",
                      )));
                }
              },
            ),
          ),
        );
      }
    }
    for (var v in d.versions) {
      var author = nicks[v.authorId] ?? "Incognito";
      DateFormat formatter = DateFormat('E d H:m');
      var modTime = formatter.format(v.modTime);
      switch (v.state) {
        case sp.DocumentState.updated:
          var localPath = "";
          var message = "";
          var title = "";
          var editable = false;
          if (d.localPath.isEmpty) {
            localPath = path.join(_appDir, poolName, d.name);
            title = "receive a new file from $author,"
                " added on $modTime";
            message = "new content";
            editable = !Platform.isAndroid && !Platform.isIOS;
          } else {
            localPath = d.localPath;
            title = "receive an update from $author,"
                " added on $modTime";
            message = "the file contains an update on something you have";
            editable = false;
          }

          items.add(
            Card(
              child: ListTile(
                title: Text(title),
                leading: const Icon(Icons.download),
                onTap: () {
                  Navigator.pushNamed(context, "/apps/library/download",
                      arguments: DownloadFileArgs(poolName, v.id, message,
                          localPath, editable, v.modTime, v.size));
                },
              ),
            ),
          );
          break;
        case sp.DocumentState.conflict:
          var message =
              "the file was created from an older version than yours; "
              "you may lose some data if you update";
          var title = "replace with a conflicting file from $author,"
              " added on $modTime";
          title = "receive a new file from $author,"
              " added on $modTime";
          message = "new content";
          items.add(
            Card(
              child: ListTile(
                title: Text(
                  title,
                  style: const TextStyle(color: Colors.amber),
                ),
                leading: const Icon(Icons.download),
                onTap: () {
                  try {
                    Navigator.pushNamed(context, "/apps/library/download",
                        arguments: DownloadFileArgs(poolName, v.id, message,
                            d.localPath, false, v.modTime, v.size));
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: Colors.red,
                        content: Text(
                          "Cannot upload ${d.name}: $e",
                        )));
                  }
                },
              ),
            ),
          );
          break;
        default:
          break;
      }
    }

    if (d.localPath.isNotEmpty) {
      items.add(
        Card(
          child: ListTile(
            title: const Text("Delete Locally"),
            leading: const Icon(Icons.delete),
            onTap: () {
              deleteFile(context, d.localPath).then((deleted) {
                if (deleted ?? false) Navigator.pop(context);
              });
            },
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Library $poolName"),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Column(children: [
          ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(8),
            children: items,
          ),
        ]),
      ),
      bottomNavigationBar: MainNavigationBar(poolName),
    );
  }
}
