import 'package:caspian/apps/library/library.dart';
import 'package:caspian/safepool/safepool.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breadcrumb/flutter_breadcrumb.dart';

class UploadFile extends StatefulWidget {
  const UploadFile({super.key});

  @override
  State<UploadFile> createState() => _UploadFileState();
}

class _UploadFileState extends State<UploadFile> {
  final _formKey = GlobalKey<FormState>();
  late String _poolName;
  String _targetFolder = "";
  String _targetName = "";
  bool _copyLocally = false;
  bool _uploading = false;
  final Map<String, List<String>> _virtualFolders = {};
  final TextEditingController _createFolderController = TextEditingController();

  Future<String?> _createFolderDialog(BuildContext context) async {
    return showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Create Folder'),
            content: TextField(
              controller: _createFolderController,
              decoration: const InputDecoration(hintText: "Name"),
            ),
            actions: [
              ElevatedButton(
                child: const Text('Confirm'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  Widget _getFolderSelection(BuildContext context) {
    var ls = libraryList(_poolName, _targetFolder);

    var crumbs = <BreadCrumbItem>[
      BreadCrumbItem(
        content: Text(_poolName),
        onTap: () {
          setState(() {
            _targetFolder = "";
          });
        },
      ),
    ];
    var s = "";
    _targetFolder.split("/").forEach((n) {
      if (n.isNotEmpty) {
        s = s.isEmpty ? n : "$s/$n";
        crumbs.add(BreadCrumbItem(
            content: Text(n),
            onTap: () {
              setState(() {
                _targetFolder = s;
              });
            }));
      }
    });

    var subfolders = (_virtualFolders[_targetFolder] ?? []) + ls.subfolders;
    var items = subfolders
        .map((e) => ListTile(
              leading: const Icon(Icons.folder),
              title: Text(e),
              onTap: () => setState(() {
                _targetFolder = "$_targetFolder/$e";
              }),
            ))
        .toList();

    return Column(
      children: [
        Row(
          children: [
            BreadCrumb(
              items: crumbs,
              divider: const Icon(Icons.chevron_right),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                _createFolderDialog(context).then((value) {
                  var text = _createFolderController.text;
                  if (text.isNotEmpty) {
                    setState(() {
                      if (_virtualFolders[_targetFolder] != null) {
                        _virtualFolders[_targetFolder]?.add(text);
                      } else {
                        _virtualFolders[_targetFolder] = [text];
                      }
                      _createFolderController.clear();
                      _targetFolder =
                          _targetFolder.isEmpty ? text : "$_targetFolder/$text";
                    });
                  }
                });
              },
              icon: const Icon(Icons.create_new_folder),
            ),
          ],
        ),
        ListView(
          padding: const EdgeInsets.all(8.0),
          shrinkWrap: true,
          children: items,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var uploadArgs = ModalRoute.of(context)!.settings.arguments as UploadArgs;

    _poolName = uploadArgs.poolName;
    _targetName = uploadArgs.selection.name;

    var action = _uploading
        ? const CircularProgressIndicator()
        : ElevatedButton(
            onPressed: () {
              try {
                var target = _targetFolder.isEmpty
                    ? _targetName
                    : "$_targetFolder/$_targetName";

                setState(() {
                  _uploading = true;
                });
                librarySend(
                    _poolName, uploadArgs.selection.path, target, false, []);
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(
                      "Cannot upload $_targetName: $e",
                    )));
              }
            },
            child: const Text('Upload'),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text("Add ${uploadArgs.selection.name}"),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Builder(
          builder: (context) => Form(
            key: _formKey,
            child: Column(
              children: [
                _getFolderSelection(context),
                TextFormField(
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Name'),
                  initialValue: _targetName,
                  onChanged: (val) => setState(() {
                    _targetName = val;
                  }),
                ),
                Row(children: [
                  Checkbox(
                      value: _copyLocally,
                      activeColor: Colors.green,
                      onChanged: (v) {
                        setState(() {
                          _copyLocally = v ?? false;
                        });
                      }),
                  const Text('Save locally'),
                ]),
                action,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
