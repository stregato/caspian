import 'dart:convert';
import 'dart:typed_data';

List<T> dynamicToList<T>(dynamic value) {
  return ((value ?? []) as List<dynamic>).map((e) => e as T).toList();
}

class Config {
  String name = "";
  List<String> public_ = [];
  List<String> private_ = [];
  Config();

  Config.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        public_ = dynamicToList(json['public']),
        private_ = dynamicToList(json['private']);

  Map<String, dynamic> toJson() => {
        'name': name,
        'public': public_,
        'private': private_,
      };
}

class Key {
  String? public_;
  String? private_;

  Key();

  Key.fromJson(Map<String, dynamic> json)
      : public_ = json['pu'],
        private_ = json['pr'];
}

class Identity {
  String nick = "";
  String email = "";
  Key signatureKey = Key();
  Key encryptionKey = Key();
  Identity();

  String id() {
    var b = BytesBuilder();
    b.add(base64Decode(signatureKey.public_ ?? ""));
    b.add(base64Decode(encryptionKey.public_ ?? ""));
    return base64Encode(b.toBytes()).replaceAll("/", "_");
  }

  Identity.fromJson(Map<String, dynamic> json)
      : nick = json['n'],
        email = json['m'] ?? "",
        signatureKey = Key.fromJson(json["s"]),
        encryptionKey = Key.fromJson(json["e"]);
}

class Invite {
  String subject = "";
  Identity sender = Identity();
  List<String> recipientsId = List.empty();
  Config? config;
  Invite();

  Invite.fromJson(Map<String, dynamic> json)
      : config =
            json["config"] != null ? Config.fromJson(json["config"]) : null,
        sender = Identity.fromJson(json["sender"]);
}

class Pool {
  String name = "";
  Identity self;
  List<String> apps = [];
  bool trusted = false;
  String connection = "";

  Pool.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        apps = json['apps'] ?? ['chat', 'library', 'invite'],
        self = Identity.fromJson(json['self']),
        trusted = json['trusted'],
        connection = json['connection'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'apps': apps,
      };
}

class ChatMessage {
  String id;
  String author;
  DateTime time;
  String contentType;
  String text;
  Uint8List binary;

  ChatMessage()
      : id = "0",
        author = "",
        time = DateTime.now(),
        contentType = "",
        text = "",
        binary = Uint8List(0);

  ChatMessage.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        author = json['author'],
        time = DateTime.parse(json['time']),
        contentType = json['contentType'],
        text = json['text'],
        binary = base64Decode(json['binary'] ?? "");
}

enum DocumentState {
  sync,
  updated,
  modified,
  deleted,
  conflict,
  new_;

  static fromInt(int v) {
    switch (v) {
      case 1:
        return sync;
      case 2:
        return updated;
      case 4:
        return modified;
      case 8:
        return deleted;
      case 16:
        return conflict;
      case 32:
        return new_;
    }
  }
}

class LibraryVersion {
  String authorId;
  DocumentState state;
  int size;
  DateTime modTime;
  String contentType;
  Uint8List hash;
  List<String> tags;
  int id;

  LibraryVersion()
      : authorId = "",
        state = DocumentState.sync,
        size = 0,
        modTime = DateTime.now(),
        contentType = "",
        hash = Uint8List(0),
        tags = [],
        id = 0;

  LibraryVersion.fromJson(Map<String, dynamic> json)
      : authorId = json['authorId'],
        state = DocumentState.fromInt(json['state']),
        size = json['size'],
        modTime = DateTime.parse(json['modTime']),
        contentType = json['contentType'],
        hash = base64Decode(json['hash']),
        tags = dynamicToList(json['tags']),
        id = json['id'];
}

// ContentType string    `json:"contentType"`
// Hash        []byte    `json:"hash"`
// HashChain   [][]byte  `json:"hashChain"`
// Tags        []string  `json:"tags"`

class LibraryFile {
  int id;
  String name;
  int size;
  Uint8List hash;
  DateTime modTime;
  String authorId;

  LibraryFile()
      : id = 0,
        name = "",
        size = 0,
        hash = Uint8List(0),
        modTime = DateTime.now(),
        authorId = "";

  LibraryFile.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        size = json['size'],
        hash = base64Decode(json['hash'] ?? ""),
        modTime = DateTime.parse(json['modTime']),
        authorId = json['authorId'];
}

class LibraryDocument {
  String name;
  String authorId;
  String localPath;
  int id;
  DateTime modTime;
  DocumentState state;
  Uint8List hash;
  List<Uint8List> hashChain;
  List<LibraryVersion> versions;

  LibraryDocument()
      : name = "",
        authorId = "",
        localPath = "",
        id = 0,
        modTime = DateTime.now(),
        state = DocumentState.sync,
        hash = Uint8List(0),
        hashChain = [],
        versions = [];

  LibraryDocument.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        authorId = json['authorId'],
        localPath = json['localPath'],
        id = json['id'],
        modTime = DateTime.parse(json['modTime']),
        state = DocumentState.fromInt(json['state']),
        hash = base64Decode(json['hash'] ?? ""),
        hashChain = dynamicToList(json['hashChain'])
            .map((e) => base64Decode(e))
            .toList(),
        versions = dynamicToList(json['versions'])
            .map((e) => LibraryVersion.fromJson(e))
            .toList();
}

class LibraryList {
  String folder;
  List<LibraryDocument> documents;
  List<String> subfolders;

  LibraryList()
      : folder = "",
        documents = [],
        subfolders = [];

  LibraryList.fromJson(Map<String, dynamic> json)
      : folder = json['folder'],
        documents = dynamicToList(json['documents'])
            .map((e) => LibraryDocument.fromJson(e))
            .toList(),
        subfolders = dynamicToList(json['subfolders']);
}

class Notification {
  String pool;
  String app;
  String message;
  int count;

  Notification()
      : pool = "",
        app = "",
        message = "",
        count = 0;

  Notification.fromJson(Map<String, dynamic> json)
      : pool = json['pool'],
        app = json['app'],
        message = json['message'],
        count = json['count'];
}
