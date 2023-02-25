import 'dart:io';

import 'package:caspian/safepool/safepool.dart';
import 'package:flutter/material.dart';

class DownloadFile extends StatefulWidget {
  const DownloadFile({super.key});

  @override
  State<DownloadFile> createState() => _DownloadFileState();
}

class DownloadFileArgs {
  String poolName;
  int id;
  String message;
  String target;
  bool editable;
  DateTime modTime;
  int size;
  DownloadFileArgs(this.poolName, this.id, this.message, this.target,
      this.editable, this.modTime, this.size);
}

class _DownloadFileState extends State<DownloadFile> {
  final _formKey = GlobalKey<FormState>();
  late String _poolName;
  String _target = "";

  @override
  Widget build(BuildContext context) {
    var args = ModalRoute.of(context)!.settings.arguments as DownloadFileArgs;

    _poolName = args.poolName;
    if (_target.isEmpty) {
      _target = args.target;
    }
    var name = _target.split(Platform.pathSeparator).last;

    var targetSection = <Widget>[];
    targetSection.add(Text(args.message));
    targetSection.add(
      TextFormField(
        maxLines: 6,
        decoration: const InputDecoration(labelText: 'Save to'),
        initialValue: _target,
        onChanged: null,
      ),
    );
    if (args.editable) {
      targetSection
          .add(ElevatedButton(onPressed: () {}, child: const Text("Choose")));
    }

    var buttons = <Widget>[];
    buttons.add(ElevatedButton(
      onPressed: () {
        try {
          receiveDocument(_poolName, args.id, _target);
          Navigator.pop(context);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                "Cannot download $_target: $e",
              )));
        }
      },
      child: const Text('Download'),
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text("Download $name"),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Builder(
          builder: (context) => Form(
            key: _formKey,
            child: Column(
              children: targetSection,
            ),
          ),
        ),
      ),
    );
  }
}
