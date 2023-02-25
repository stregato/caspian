import 'package:caspian/safepool/safepool.dart' as sp;
import 'package:flutter/material.dart';

class PoolSettings extends StatefulWidget {
  const PoolSettings({super.key});

  @override
  State<PoolSettings> createState() => _PoolSettingsState();
}

const urlHint = "Enter a supported URL and click +";
const validSchemas = ["s3", "sftp", "file"];
const availableApps = ["chat", "library", "gallery"];

class _PoolSettingsState extends State<PoolSettings> {
  @override
  Widget build(BuildContext context) {
    final poolName = ModalRoute.of(context)!.settings.arguments as String;

    final buttonStyle = ButtonStyle(
      padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.all(20)),
    );

    var pool = sp.poolGet(poolName);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pool Settings"),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              style: buttonStyle,
              label: const Text("Create a sub-pool"),
              icon: const Icon(Icons.child_care),
              onPressed: () {
                Navigator.pushNamed(context, "/pool/sub", arguments: poolName);
              },
            ),
            const SizedBox(height: 20),
            const Text("Danger Zone",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ElevatedButton.icon(
              style: buttonStyle,
              label: const Text('Leave'),
              icon: const Icon(Icons.exit_to_app),
              onPressed: () {
                try {
                  sp.poolLeave(poolName);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(
                        "you successfully left $poolName",
                      )));

                  Navigator.of(context).popUntil((route) => route.isFirst);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(
                        "Cannot leave $poolName: $e",
                      )));
                }
              },
            ),
            const SizedBox(height: 20),
            Text("Connected via ${pool.connection}"),
          ],
        ),
      ),
    );
  }
}
