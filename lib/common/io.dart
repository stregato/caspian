import 'dart:io';
import 'dart:isolate';

import 'package:caspian/common/download.dart';
import 'package:caspian/common/progress.dart';

import './document.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

enum Type { library, downloads }

late String applicationFolder;
late String documentsFolder;
late String downloadFolder;

Future<void> initFolders() async {
  var dir = await getApplicationSupportDirectory();
  applicationFolder = dir.path;

  dir = await getApplicationDocumentsDirectory();
  documentsFolder = dir.path;

  if (Platform.isIOS) {
    downloadFolder = (await getDownloadsDirectory())!.path;
  } else if (Platform.isAndroid) {
    downloadFolder = "/storage/emulated/0/Download/";

    var dirDownloadExists = await Directory(downloadFolder).exists();
    if (dirDownloadExists) {
      downloadFolder = "/storage/emulated/0/Download/";
    } else {
      downloadFolder = "/storage/emulated/0/Downloads/";
    }
  } else if (Platform.isLinux || Platform.isMacOS) {
    downloadFolder = path.join(Platform.environment['HOME']!, "Downloads");
  } else {
    downloadFolder =
        path.join(Platform.environment['USERPROFILE']!, "Downloads");
  }
}

Future<String?> chooseFile(BuildContext context, Document document,
    {bool canChoose = false, String? message}) async {
  final downloadFile = ChooseFile(document, message, canChoose);
  return await Navigator.push<String>(
      context, MaterialPageRoute(builder: (context) => downloadFile));
}

Function() getProgress(String target, int size) {
  return () {
    var stat = FileStat.statSync(target);
    return stat.size > 0 ? stat.size / size : null;
  };
}
