import 'package:caspian/apps/library/library_actions.dart';
import 'package:caspian/navigation/bar.dart';
import 'package:caspian/safepool/safepool.dart' as sp;
import 'package:caspian/safepool/safepool_def.dart' as sp;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:caspian/apps/chat/theme.dart';
import 'package:flutter_breadcrumb/flutter_breadcrumb.dart';
import 'package:caspian/common/file_access.dart';
import 'package:file_icon/file_icon.dart';

class Library extends StatefulWidget {
  const Library({Key? key}) : super(key: key);

  @override
  State<Library> createState() => _LibraryState();
}

class LibraryArgs {
  String poolName;
  String folder;
  LibraryArgs(this.poolName, this.folder);
}

class UploadArgs {
  String poolName;
  FileSelection selection;
  UploadArgs(this.poolName, this.selection);
}

class _LibraryState extends State<Library> {
  AppTheme theme = LightTheme();

  String _folder = "";

  Color? colorForState(sp.Document d) {
    switch (d.state) {
      case sp.DocumentState.sync:
        return Colors.green;
      case sp.DocumentState.updated:
        return Colors.blue;
      case sp.DocumentState.modified:
        return Colors.yellow;
      case sp.DocumentState.deleted:
        return Colors.redAccent;
      case sp.DocumentState.conflict:
        return Colors.blue;
      case sp.DocumentState.new_:
        return Colors.blue;
    }
  }

  Widget? subForState(sp.Document d) {
    switch (d.state) {
      case sp.DocumentState.sync:
        return null;
      case sp.DocumentState.updated:
        return const Text("updated");
      case sp.DocumentState.modified:
        return const Text("modified");
      case sp.DocumentState.deleted:
        return const Text("deleted");
      case sp.DocumentState.conflict:
        return const Text("conflict");
      case sp.DocumentState.new_:
        return const Text("new");
    }
  }

  @override
  Widget build(BuildContext context) {
    String poolName = "";

    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is String) {
      poolName = args;
    } else if (args is LibraryArgs) {
      poolName = args.poolName;
      _folder = args.folder;
    }

    var list = sp.libraryList(poolName, _folder);
    var items = list.subfolders
        .map(
          (e) => Card(
            child: ListTile(
              title: Text(e),
              leading: const Icon(Icons.folder),
              onTap: () => setState(() {
                _folder = _folder.isEmpty ? e : "$_folder/$e";
              }),
            ),
          ),
        )
        .toList();

    items.addAll(
      list.documents
          .map(
            (d) => Card(
              child: ListTile(
                title: Text(d.name.split("/").last,
                    style: TextStyle(color: colorForState(d))),
                subtitle: subForState(d),
                leading: FileIcon(d.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, "/apps/library/actions",
                          arguments: LibraryActionsArgs(poolName, d))
                      .then((value) => setState(
                            () {},
                          ));
                },
              ),
            ),
          )
          .toList(),
    );

    var breadcrumbsItems = <BreadCrumbItem>[
      BreadCrumbItem(
        content: RichText(
          text: TextSpan(
            text: poolName,
            style: const TextStyle(color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () => setState(
                    () {
                      _folder = "";
                    },
                  ),
          ),
        ),
      ),
    ];

    breadcrumbsItems.addAll(_folder.split("/").map(
          (e) => BreadCrumbItem(
            content: RichText(
              text: TextSpan(
                text: e,
                style: const TextStyle(color: Colors.blue),
                recognizer: TapGestureRecognizer()..onTap = () {},
              ),
            ),
          ),
        ));

    return Scaffold(
      appBar: AppBar(
        title: Text("Library $poolName"),
        actions: [
          ElevatedButton.icon(
            label: const Text("Reload"),
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Column(children: [
          Row(
            children: [
              BreadCrumb(
                items: breadcrumbsItems,
                divider: const Icon(Icons.chevron_right),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  getFile(context).then((s) {
                    if (s.valid) {
                      Navigator.pushNamed(context, "/apps/library/upload",
                              arguments: UploadArgs(poolName, s))
                          .then((value) => setState(
                                () {},
                              ));
                    }
                  });
                },
                icon: const Icon(Icons.upload_file),
              ),
            ],
          ),
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
