import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:caspian/common/io.dart';
import 'package:caspian/safepool/safepool.dart';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'caspian_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  initFolders().then((_) {
    Connectivity().checkConnectivity().then((c) {
      var availableBandwidth =
          Platform.isMacOS || Platform.isLinux || Platform.isWindows
              ? "high"
              : c == ConnectivityResult.wifi
                  ? "medium"
                  : "low";
      start("$applicationFolder/.safepool.db", availableBandwidth);
      runApp(const CaspianApp());
    });
  });

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('Caspian on Desktop');
    getCurrentScreen().then((screen) {
      doWhenWindowReady(() {
        var height = screen?.frame.height ?? 800;
        var width = (screen?.frame.width ?? 1024) * 0.2;
        // if (width < 200) width = 200;
        if (width > 600) width = 600;

        appWindow.minSize = Size(width, height);
        appWindow.size = Size(width, height);
        appWindow.alignment = Alignment.topRight;
        appWindow.show();
      });
    });
  }
}
