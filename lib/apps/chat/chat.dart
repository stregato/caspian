import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'dart:typed_data';

import 'package:caspian/apps/library/library.dart';
import 'package:caspian/common/const.dart';
import 'package:caspian/common/image.dart';
import 'package:caspian/common/io.dart';
import 'package:caspian/common/progress.dart';
import 'package:caspian/navigation/bar.dart';
import 'package:caspian/safepool/safepool_def.dart' as sp;
import 'package:caspian/safepool/safepool.dart' as sp;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as chat;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as ph;

class ChatArgs {
  String poolName;
  sp.ChatPrivate private;
  ChatArgs(this.poolName, this.private);
}

class Chat extends StatefulWidget {
  const Chat({Key? key}) : super(key: key);

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final List<types.Message> _messages = [];
  String _poolName = "";
  sp.ChatPrivate _private = [];
  DateTime _from = DateTime.fromMicrosecondsSinceEpoch(0);
  DateTime _to = DateTime.fromMicrosecondsSinceEpoch(0);
  Timer? timer;
  DateTime _lastMessage = DateTime.now();
  late types.User _currentUser;
  final Map<String, types.User> _users = {};
  final Set<String> _loaded = {};
  final double _pageThresold = isDesktop ? 40 : 20;
  bool _isLastPage = false;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(
      const Duration(seconds: 3),
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

  types.Message _convertHtml(sp.ChatMessage m, types.User user) {
    return types.CustomMessage(
        id: m.id,
        author: user,
        createdAt: m.time.millisecondsSinceEpoch,
        metadata: {
          'mime': m.contentType,
          'data': m.text,
        });
  }

  types.Message _convertText(sp.ChatMessage m, types.User user) {
    return types.TextMessage(
        id: m.id,
        text: m.text,
        author: user,
        createdAt: m.time.millisecondsSinceEpoch);
  }

  types.Message _convertLibraryFile(sp.ChatMessage m, types.User user) {
    return types.FileMessage(
        author: user,
        createdAt: m.time.millisecondsSinceEpoch,
        id: m.id,
        mimeType: m.contentType,
        name: ph.basename(m.text),
        uri: m.text,
        size: 1);
  }

  types.Message _convertEmbeddedImage(sp.ChatMessage m, types.User user) {
    var size = m.binary.length;
    var file = File("$temporaryFolder/${m.id}");
    var stat = FileStat.statSync(file.path);
    if (stat.size != size) {
      file.writeAsBytesSync(m.binary, flush: true);
    }

    return types.ImageMessage(
      author: user,
      createdAt: m.time.millisecondsSinceEpoch,
      id: m.id,
      name: m.id,
      size: size,
      uri: file.path,
    );
  }

  types.Message _convert(sp.ChatMessage m) {
    try {
      var user = _users[m.author] ?? types.User(id: m.author);
      _loaded.add(m.id);

      if (m.contentType == 'text/html') {
        return _convertHtml(m, user);
      }
      if (m.contentType.startsWith('text/')) {
        return _convertText(m, user);
      }
      if (m.contentType.startsWith("image/") && m.binary.isNotEmpty) {
        return _convertEmbeddedImage(m, user);
      }
      if (m.text.startsWith("library:/")) {
        return _convertLibraryFile(m, user);
      }
      return types.TextMessage(
          id: m.id,
          text:
              "Unsupported message with content type ${m.contentType}: ${m.text}",
          createdAt: m.time.millisecondsSinceEpoch,
          author: types.User(id: m.author));
    } catch (err) {
      return types.TextMessage(
          id: m.id,
          createdAt: m.time.millisecondsSinceEpoch,
          text: "Error: $err",
          author: types.User(id: m.author));
    }
  }

  static _chatReceive(String poolName, DateTime after, DateTime before,
      sp.ChatPrivate private) {
    return Isolate.run<List<sp.ChatMessage>>(() =>
        sp.chatReceive(poolName, after, before, isDesktop ? 40 : 20, private));
  }

  _loadMoreMessages([bool showProgress = false]) async {
    var messages = showProgress
        ? await progressDialog<List<sp.ChatMessage>>(
            context,
            "Getting messages",
            _chatReceive(_poolName, _from, DateTime.now(), _private))
        : sp.chatReceive(_poolName, _to, DateTime.now(), 100, _private);
    if (messages == null || messages.isEmpty) {
      return;
    }
    setState(() {
      for (var m in messages) {
        if (!_loaded.contains(m.id)) {
          _messages.insert(0, _convert(m));
          _loaded.add(m.id);
        }
      }
      _isLastPage =
          _from.millisecondsSinceEpoch == 0 && messages.length < _pageThresold;
      if (_from.microsecondsSinceEpoch == 0) {
        _from = messages.first.time;
      }
      _to = messages.last.time;
      _lastMessage = DateTime.now();
    });
  }

  Widget _customMessageBuilder(types.CustomMessage message,
      {required int messageWidth}) {
    var mime = message.metadata?['mime'];
    switch (mime) {
      case 'text/html':
        var data = message.metadata?['data'];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              chat.UserName(author: message.author),
              html.Html(
                data: data,
                style: {'*': html.Style(fontSize: html.FontSize(14))},
              ),
            ],
          ),
        );
      default:
        return Text("unsupported type $mime");
    }
  }

  Future<void> _handleEndReached() async {
    var after = DateTime.fromMicrosecondsSinceEpoch(0);
    var before = _from;
    var messages = await progressDialog<List<sp.ChatMessage>>(context,
        "Getting messages", _chatReceive(_poolName, after, before, _private));

    setState(() {
      if (messages == null || messages.isEmpty) {
        _isLastPage = true;
        return;
      }

      for (var m in messages.reversed) {
        if (!_loaded.contains(m.id)) {
          _messages.add(_convert(m));
          _loaded.add(m.id);
        }
      }
      _isLastPage = messages.length < _pageThresold;
      _from = messages.first.time;
    });
  }

  void _handleSendPressed(types.PartialText message) {
    var id = sp.chatSend(
        _poolName, "text/plain", message.text, Uint8List(0), _private);

    final textMessage = types.TextMessage(
      author: _currentUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: "$id",
      text: message.text,
    );

    _loaded.add("$id");
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
                  _handleImageSelection(context);
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

  void _addFile(String filePath) async {
    var size = File(filePath).lengthSync();
    var name = ph.basename(filePath);
    sp.librarySend(_poolName, filePath, "uploads/$name", true, []);
    final mimeType = lookupMimeType(filePath);

    var uri = "library:/uploads/$name";
    var id = sp.chatSend(_poolName, mimeType!, uri, Uint8List(0), _private);

    final message = types.FileMessage(
      author: _currentUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: "$id",
      mimeType: mimeType,
      name: name,
      size: size,
      uri: uri,
    );
    _loaded.add("$id");

    _addMessage(message);
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: "file to send",
        initialDirectory: documentsFolder);

    for (var file in result!.files) {
      _addFile(file.path!);
      // var name = ph.basename(localPath);
      // sp.librarySend(_poolName, localPath, "uploads/$name", true, []);
      // final mimeType = lookupMimeType(localPath);

      // var uri = "library:/uploads/$name";
      // var id = sp.chatSend(_poolName, mimeType!, uri, Uint8List(0), _private);

      // final message = types.FileMessage(
      //   author: _currentUser,
      //   createdAt: DateTime.now().millisecondsSinceEpoch,
      //   id: "$id",
      //   mimeType: mimeType,
      //   name: name,
      //   size: result.files.single.size,
      //   uri: uri,
      // );
      // _loaded.add("$id");

      // _addMessage(message);
    }
  }

  void _addImage(XFile xfile) async {
    final bytes = await xfile.readAsBytes();
    final image = await decodeImageFromList(bytes);

    final mimeType = lookupMimeType(xfile.path);
    var id = sp.chatSend(
        _poolName, mimeType ?? "image/jpeg", xfile.name, bytes, _private);

    final message = types.ImageMessage(
      author: _currentUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      height: image.height.toDouble(),
      id: "$id",
      name: xfile.name,
      size: bytes.length,
      uri: xfile.path,
      width: image.width.toDouble(),
    );

    _addMessage(message);
  }

  void _handleImageSelection(BuildContext context) async {
    XFile? xfile = await pickImage();

    if (xfile != null) {
      _addImage(xfile);
    }
  }

  void _handleMessageTap(BuildContext context, types.Message message) async {
    if (message is types.FileMessage) {
      if (message.uri.startsWith('library:/')) {
        var folder = message.uri.replaceFirst("library:/", "");
        var idx = folder.lastIndexOf('/');
        folder = idx == -1 ? "" : folder.substring(0, idx);

        Navigator.pushNamed(context, "/apps/library",
            arguments: LibraryArgs(_poolName, folder));
      }
    }
  }

  Future<bool?> _inlineImagesDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Images or Files?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('The dropped files contain images'),
                Text('Would you like to inline as images or add as files?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Inlined Images'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            TextButton(
              child: const Text('Files'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    );
  }

  void _dropFiles(List<XFile> files) async {
    var imageFiles = files.where((f) {
      var mimeType = lookupMimeType(f.path);
      return mimeType.toString().startsWith("image/");
    });
    var inlineImages =
        imageFiles.isNotEmpty ? await _inlineImagesDialog() ?? false : false;

    for (var f in files) {
      if (inlineImages && imageFiles.contains(f)) {
        _addImage(f);
      } else {
        _addFile(f.path);
      }
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _addMessage(types.Message message) {
    setState(() {
      _loaded.add(message.id);
      _messages.insert(0, message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is String) {
      if (_poolName != args) {
        _poolName = args;
      }
    } else if (args is ChatArgs) {
      if (_poolName != args.poolName) {
        _poolName = args.poolName;
        _private = args.private;
      }
    }

    if (_users.isEmpty) {
      _setUsers();
      Future.delayed(
          const Duration(milliseconds: 10), () => _loadMoreMessages(true));
    }

    var title = _private.isEmpty ? "Chat $_poolName" : "Private $_poolName";

    var privateChips = _private
        .map((e) => _users[e]?.firstName!)
        .where((e) => e != null)
        .map((e) => Chip(
              avatar: CircleAvatar(
                backgroundColor: Colors.grey.shade800,
                child: Text(e!.substring(0, 1)),
              ),
              label: Text(e),
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ElevatedButton.icon(
            label: const Text("Sub"),
            onPressed: () {
              Navigator.pushNamed(context, "/pool/sub", arguments: _poolName);
            },
            icon: const Icon(Icons.child_care),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            child: Row(
              children: privateChips,
            ),
          ),
          DropTarget(
            onDragDone: (details) async {
              _dropFiles(details.files);
            },
            child: Expanded(
              child: chat.Chat(
                messages: _messages,
                onAttachmentPressed: () {
                  _handleAttachmentPressed(context);
                },
                onMessageTap: _handleMessageTap,
                onPreviewDataFetched: _handlePreviewDataFetched,
                onSendPressed: _handleSendPressed,
                onEndReached: _handleEndReached,
                // onEndReachedThreshold: _pageThresold,
                isLastPage: _isLastPage,
                showUserAvatars: true,
                showUserNames: true,
                user: _currentUser,
                customMessageBuilder: _customMessageBuilder,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MainNavigationBar(_poolName),
    );
  }
}
