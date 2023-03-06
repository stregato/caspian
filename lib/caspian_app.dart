import 'package:caspian/apps/chat/chat.dart';
import 'package:caspian/apps/invite/invite.dart';
import 'package:caspian/apps/invite/invite_list.dart';
import 'package:caspian/apps/library/library.dart';
import 'package:caspian/apps/library/library_actions.dart';
import 'package:caspian/apps/library/upload_file.dart';

import 'package:caspian/pool/addpool.dart';
import 'package:caspian/pool/create.dart';
import 'package:caspian/pool/import.dart';
import 'package:caspian/pool/pool.dart';
import 'package:caspian/pool/home.dart';
import 'package:caspian/pool/settings.dart';
import 'package:caspian/pool/subpool.dart';
import 'package:caspian/settings/settings.dart';
import 'package:flutter/material.dart';

class CaspianApp extends StatelessWidget {
  const CaspianApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caspian',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: "/",
      routes: {
        "/": (context) => const Home(),
        "/addPool": (context) => const AddPool(),
        "/addPool/create": (context) => const CreatePool(),
        "/addPool/import": (context) => const ImportPool(),
        "/settings": (context) => const Settings(),
        "/pool": (context) => const Pool(),
        "/pool/sub": (context) => const SubPool(),
        "/pool/settings": (context) => const PoolSettings(),
        "/apps/chat": (context) => const Chat(),
        "/apps/library": (context) => const Library(),
        "/apps/library/upload": (context) => const UploadFile(),
//        "/apps/library/download": (context) => const DownloadFile(),
        "/apps/library/actions": (context) => const LibraryActions(),
        "/apps/invite": (context) => const Invite(),
        "/apps/invite/list": (context) => const InviteList(),
      },
    );
  }
}
