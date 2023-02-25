import 'dart:ffi' as ffi; // For FFI
import 'dart:io'; // For Platform.isX
import 'dart:convert';
import 'dart:typed_data';
import 'package:caspian/safepool/safepool_def.dart';
import "package:ffi/ffi.dart";
import 'safepool_platform_interface.dart';

final ffi.DynamicLibrary lib = getLibrary();

ffi.DynamicLibrary getLibrary() {
  if (Platform.isAndroid) {
    return ffi.DynamicLibrary.open('libsafepool.so');
  }
  if (Platform.isLinux) {
    return ffi.DynamicLibrary.open('linux/libs/amd64/libsafepool.so');
  }
  return ffi.DynamicLibrary.process();
}

class Safepool {
  Future<String?> getPlatformVersion() {
    return SafepoolPlatform.instance.getPlatformVersion();
  }
}

class CResult extends ffi.Struct {
  external ffi.Pointer<Utf8> res;
  external ffi.Pointer<Utf8> err;

  void unwrapVoid() {
    if (err.address != 0) {
      throw CException(err.toDartString());
    }
  }

  String unwrapString() {
    unwrapVoid();
    if (res.address == 0) {
      return "";
    }

    return jsonDecode(res.toDartString()) as String;
  }

  int unwrapInt() {
    unwrapVoid();

    return jsonDecode(res.toDartString()) as int;
  }

  Map<String, dynamic> unwrapMap() {
    unwrapVoid();
    if (res.address == 0) {
      return {};
    }

    return jsonDecode(res.toDartString()) as Map<String, dynamic>;
  }

  List<dynamic> unwrapList() {
    if (err.address != 0) {
      throw CException(err.toDartString());
    }
    if (res.address == 0) {
      return [];
    }

    var ls = jsonDecode(res.toDartString());

    return ls == null ? [] : ls as List<dynamic>;
  }
}

class CException implements Exception {
  String msg;
  CException(this.msg);

  @override
  String toString() {
    return msg;
  }
}

typedef Start = CResult Function(ffi.Pointer<Utf8>);
void start(String dbPath) {
  var startC = lib.lookupFunction<Start, Start>("start");
  startC(dbPath.toNativeUtf8()).unwrapVoid();
}

typedef GetSelfId = CResult Function();
String getSelfId() {
  var getSelfIdC = lib.lookupFunction<GetSelfId, GetSelfId>("getSelfId");
  return getSelfIdC().unwrapString();
}

typedef PoolList = CResult Function();
List<String> poolList() {
  var poolListC = lib.lookupFunction<PoolList, PoolList>("poolList");
  return poolListC().unwrapList().map((e) => e as String).toList();
}

typedef PoolCreate = CResult Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
void poolCreate(Config c, List<String> apps) {
  var poolCreateC = lib.lookupFunction<PoolCreate, PoolCreate>("poolCreate");
  var appsJson = "[${apps.map((e) => jsonEncode(e)).toList().join(",")}]";
  var cJson = jsonEncode(c.toJson());
  return poolCreateC(cJson.toNativeUtf8(), appsJson.toNativeUtf8())
      .unwrapVoid();
}

typedef PoolJoin = CResult Function(ffi.Pointer<Utf8>);
Config poolJoin(String token) {
  var poolJoinC = lib.lookupFunction<PoolJoin, PoolJoin>("poolJoin");
  var m = poolJoinC(token.toNativeUtf8()).unwrapMap();
  return Config.fromJson(m);
}

typedef PoolLeave = CResult Function(ffi.Pointer<Utf8>);
void poolLeave(String name) {
  var poolLeaveC = lib.lookupFunction<PoolJoin, PoolJoin>("poolLeave");
  poolLeaveC(name.toNativeUtf8()).unwrapVoid();
}

typedef PoolSub = CResult Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
String poolSub(String name, String sub, List<String> ids, List<String> apps) {
  var poolSubC = lib.lookupFunction<PoolSub, PoolSub>("poolSub");
  return poolSubC(name.toNativeUtf8(), sub.toNativeUtf8(),
          jsonEncode(ids).toNativeUtf8(), jsonEncode(apps).toNativeUtf8())
      .unwrapString();
}

typedef PoolInvite = CResult Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
String poolInvite(String poolName, List<String> ids, String invitePool) {
  var poolInviteC = lib.lookupFunction<PoolInvite, PoolInvite>("poolInvite");

  var token = poolInviteC(poolName.toNativeUtf8(),
          jsonEncode(ids).toNativeUtf8(), invitePool.toNativeUtf8())
      .unwrapString();
  return token;
}

typedef PoolGet = CResult Function(ffi.Pointer<Utf8>);
Pool poolGet(String name) {
  var poolGetC = lib.lookupFunction<PoolGet, PoolGet>("poolGet");
  var m = poolGetC(name.toNativeUtf8()).unwrapMap();
  return Pool.fromJson(m);
}

typedef PoolUsers = CResult Function(ffi.Pointer<Utf8>);
List<Identity> poolUsers(String name) {
  var poolUsersC = lib.lookupFunction<PoolUsers, PoolUsers>("poolUsers");
  var m = poolUsersC(name.toNativeUtf8()).unwrapList();
  return m.map((e) => Identity.fromJson(e)).toList();
}

typedef PoolParseInvite = CResult Function(ffi.Pointer<Utf8>);
Invite poolParseInvite(String token) {
  var validateInviteC =
      lib.lookupFunction<PoolParseInvite, PoolParseInvite>("poolParseInvite");
  var m = validateInviteC(token.toNativeUtf8()).unwrapMap();
  return Invite.fromJson(m);
}

typedef ChatReceiveC = CResult Function(
    ffi.Pointer<Utf8>, ffi.Int64, ffi.Int64, ffi.Int32);
typedef ChatReceive = CResult Function(ffi.Pointer<Utf8>, int, int, int);
List<Message> chatReceive(
    String poolName, DateTime after, DateTime before, int limit) {
  var getMessagesC =
      lib.lookupFunction<ChatReceiveC, ChatReceive>("chatReceive");
  var m = getMessagesC(poolName.toNativeUtf8(), after.microsecondsSinceEpoch,
          before.microsecondsSinceEpoch, limit)
      .unwrapList();

  return m.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
}

typedef ChatSend = CResult Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
int postMessage(
    String poolName, String contentType, String text, Uint8List binary) {
  var chatSendC = lib.lookupFunction<ChatSend, ChatSend>("chatSend");

  var r = chatSendC(
    poolName.toNativeUtf8(),
    contentType.toNativeUtf8(),
    text.toNativeUtf8(),
    base64Encode(binary).toNativeUtf8(),
  );
  return r.unwrapInt();
}

typedef LibraryListT = CResult Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
LibraryList libraryList(String poolName, String folder) {
  var libraryListC =
      lib.lookupFunction<LibraryListT, LibraryListT>("libraryList");
  var m =
      libraryListC(poolName.toNativeUtf8(), folder.toNativeUtf8()).unwrapMap();

  return LibraryList.fromJson(m);
}

// librarySend(poolName *C.char, localPath *C.char, name *C.char, solveConflicts C.int, tagsList *C.char) C.Result {
typedef LibrarySendC = CResult Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>, ffi.Int, ffi.Pointer<Utf8>);
typedef LibrarySendD = CResult Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>, int, ffi.Pointer<Utf8>);
void librarySend(String poolName, String localPath, String name,
    bool solveConflicts, List<String> tags) {
  var librarySendC =
      lib.lookupFunction<LibrarySendC, LibrarySendD>("librarySend");
  var m = librarySendC(poolName.toNativeUtf8(), localPath.toNativeUtf8(),
      name.toNativeUtf8(), solveConflicts ? 1 : 0, "[]".toNativeUtf8());
  m.unwrapVoid();
}

// receiveDocument(poolName *C.char, id C.long, localPath *C.char) C.Result
typedef ReceiveDocumentC = CResult Function(
    ffi.Pointer<Utf8>, ffi.Int, ffi.Pointer<Utf8>);
typedef ReceiveDocumentD = CResult Function(
    ffi.Pointer<Utf8>, int, ffi.Pointer<Utf8>);
void receiveDocument(String poolName, int id, String localPath) {
  var receiveDocumentC =
      lib.lookupFunction<ReceiveDocumentC, ReceiveDocumentD>("receiveDocument");
  var m =
      receiveDocumentC(poolName.toNativeUtf8(), id, localPath.toNativeUtf8());
  m.unwrapVoid();
}

// inviteReceive(poolName *C.char, after, onlyMine C.int) C.Result {
typedef InviteReceiveC = CResult Function(
    ffi.Pointer<Utf8>, ffi.Int64, ffi.Int32);
typedef InviteReceiveD = CResult Function(ffi.Pointer<Utf8>, int, int);
List<Invite> inviteReceive(String poolName, DateTime after, bool onlyMine) {
  var inviteReceiveC =
      lib.lookupFunction<InviteReceiveC, InviteReceiveD>("inviteReceive");
  var m = inviteReceiveC(poolName.toNativeUtf8(), after.microsecondsSinceEpoch,
          onlyMine ? 1 : 0)
      .unwrapList();

  return m.map((e) => Invite.fromJson(e as Map<String, dynamic>)).toList();
}

typedef NotificationsC = CResult Function(ffi.Int64);
typedef NotificationsD = CResult Function(int);
List<Notification> notifications(DateTime after) {
  var notificationsC =
      lib.lookupFunction<NotificationsC, NotificationsD>("notifications");
  var m = notificationsC(after.microsecondsSinceEpoch).unwrapList();

  return m
      .map((e) => Notification.fromJson(e as Map<String, dynamic>))
      .toList();
}

typedef FileOpen = CResult Function(ffi.Pointer<Utf8>);
void fileOpen(String filePath) {
  var fileOpenC = lib.lookupFunction<FileOpen, FileOpen>("fileOpen");
  var m = fileOpenC(filePath.toNativeUtf8());
  m.unwrapVoid();
}
