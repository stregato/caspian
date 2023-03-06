import 'dart:async';

import 'dart:typed_data';

import 'package:caspian/navigation/bar.dart';
import 'package:caspian/safepool/safepool.dart' as sp;
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as chat;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

class Chat extends StatefulWidget {
  const Chat({Key? key}) : super(key: key);

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final List<types.Message> _messages = [];
  String _poolName = "";
  DateTime _after = DateTime.fromMicrosecondsSinceEpoch(0);
  DateTime _before = DateTime.fromMicrosecondsSinceEpoch(0);
  Timer? timer;
  DateTime _lastMessage = DateTime.now();
  late types.User _currentUser;
  final Map<String, types.User> _users = {};
  final Set<String> _loaded = {};

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(
      const Duration(seconds: 5),
      (Timer t) {
        var diff = DateTime.now().difference(_lastMessage).inSeconds;
        if (diff < 20 || diff > 50) {
          _loadMoreMessages();
        }
      },
    );
  }

  void _setUsers() {
    var p = sp.poolGet(_poolName);
    _currentUser = types.User(
        id: p.self.id(), firstName: p.self.nick, lastName: p.self.email);

    for (var u in sp.poolUsers(_poolName)) {
      _users[u.id()] =
          types.User(id: u.id(), firstName: u.nick, lastName: u.email);
    }
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  void _loadMoreMessages() {
    _before = DateTime.now();
    var messages = sp.chatReceive(_poolName, _after, _before, 100);
    messages = messages.where((e) => !_loaded.contains(e.id)).toList();
    if (messages.isNotEmpty) {
      setState(() {
        _messages.addAll(messages.map((e) {
          var user = _users[e.author] ?? types.User(id: e.author);
          _loaded.add(e.id);
          switch (e.contentType) {
            case 'text/plain':
              return types.TextMessage(id: e.id, text: e.text, author: user);
            default:
              return types.TextMessage(
                  id: e.id,
                  createdAt: e.time.millisecondsSinceEpoch,
                  text: "unsupported content ${e.contentType}",
                  author: types.User(id: e.author));
          }
        }).toList());

        _after = messages.last.time;
        _lastMessage = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final poolName = ModalRoute.of(context)!.settings.arguments as String;

    if (_poolName.isEmpty) {
      _poolName = poolName;
      _setUsers();
      _loadMoreMessages();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Chat $poolName"),
        actions: [
          ElevatedButton.icon(
            label: const Text("Sub"),
            onPressed: () {
              Navigator.pushNamed(context, "/pool/sub", arguments: poolName);
            },
            icon: const Icon(Icons.child_care),
          ),
        ],
      ),
      body: chat.Chat(
        messages: _messages,
        onAttachmentPressed: () {
          _handleAttachmentPressed(context);
        },
        // onMessageTap: _handleMessageTap,
        // onPreviewDataFetched: _handlePreviewDataFetched,
        onSendPressed: _handleSendPressed,
        showUserAvatars: true,
        showUserNames: true,
        user: _currentUser,
      ),
      bottomNavigationBar: MainNavigationBar(poolName),
    );
  }

  void _handleSendPressed(types.PartialText message) {
    var id = sp.chatSend(_poolName, "text/plain", message.text, Uint8List(0));

    final textMessage = types.TextMessage(
      author: _currentUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: "$id",
      text: message.text,
    );

    _addMessage(textMessage);
  }

  void _handleAttachmentPressed(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      var localPath = result.files.single.path!;
      sp.librarySend(
          _poolName, localPath, "uploads/${basename(localPath)}", true, []);
      final mimeType = lookupMimeType(result.files.single.path!);

      var id = sp.chatSend(
          _poolName, mimeType!, "uploads/${basename(localPath)}", Uint8List(0));

      final message = types.FileMessage(
        author: _currentUser,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: "$id",
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: localPath,
      );

      _addMessage(message);
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final mimeType = lookupMimeType(result.path);
      var id = sp.chatSend(_poolName, mimeType ?? "image/jpeg", "", bytes);

      final message = types.ImageMessage(
        author: _currentUser,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: "$id",
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      _addMessage(message);
    }
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }
}
