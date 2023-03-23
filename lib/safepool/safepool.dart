import 'dart:ffi' as ffi; // For FFI
import 'dart:io'; // For Platform.isX
import 'dart:convert';
import 'package:caspian/safepool/safepool_def.dart';
import "package:ffi/ffi.dart";
import 'package:flutter/foundation.dart';
import 'safepool_platform_interface.dart';

final ffi.DynamicLibrary lib = getLibrary();

ffi.DynamicLibrary getLibrary() {
  if (Platform.isAndroid) {
    return ffi.DynamicLibrary.open('libsafepool.so');
  }
  if (Platform.isLinux) {
    if (kDebugMode) {
      return ffi.DynamicLibrary.open('linux/libs/amd64/libsafepool.so');
    } else {
      try {
        return ffi.DynamicLibrary.open('libsafepool.so');
      } catch (_) {}
      return ffi.DynamicLibrary.open('/usr/lib/libsafepool.so');
    }
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

  String unwrapRaw() {
    unwrapVoid();
    if (res.address == 0) {
      return "";
    }

    return res.toDartString();
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

typedef Start = CResult Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
void start(String dbPath, String cacheFolder, String availableBandwith) {
  var startC = lib.lookupFunction<Start, Start>("start");
  startC(dbPath.toNativeUtf8(), cacheFolder.toNativeUtf8(),
          availableBandwith.toNativeUtf8())
      .unwrapVoid();
}

typedef Stop = CResult Function();
void stop() {
  var fun = lib.lookupFunction<Stop, Stop>("stop");
  fun().unwrapVoid();
}

typedef FactoryReset = CResult Function();
void factoryReset() {
  var fun = lib.lookupFunction<FactoryReset, FactoryReset>("factoryReset");
  fun().unwrapVoid();
}

typedef SecuritySelfId = CResult Function();
String securitySelfId() {
  var fun =
      lib.lookupFunction<SecuritySelfId, SecuritySelfId>("securitySelfId");
  return fun().unwrapString();
}

typedef SecurityGetSelf = CResult Function();
Identity securityGetSelf() {
  var fun =
      lib.lookupFunction<SecurityGetSelf, SecurityGetSelf>("securityGetSelf");
  var m = fun().unwrapMap();
  return Identity.fromJson(m);
}

typedef SecuritySetSelf = CResult Function(ffi.Pointer<Utf8>);
void securitySetSelf(Identity i) {
  var fun =
      lib.lookupFunction<SecuritySetSelf, SecuritySetSelf>("securitySetSelf");
  var j = jsonEncode(i);
  fun(j.toNativeUtf8()).unwrapVoid();
}

typedef SecurityIdentityFromId = CResult Function(ffi.Pointer<Utf8>);
String securityIdentityFromId(String id) {
  var fun = lib.lookupFunction<SecurityIdentityFromId, SecurityIdentityFromId>(
      "securitySelfId");
  return fun(id.toNativeUtf8()).unwrapString();
}

typedef PoolList = CResult Function();
List<String> poolList() {
  var fun = lib.lookupFunction<PoolList, PoolList>("poolList");
  return fun().unwrapList().map((e) => e as String).toList();
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
    ffi.Pointer<Utf8>, ffi.Int64, ffi.Int64, ffi.Int32, ffi.Pointer<Utf8>);
typedef ChatReceive = CResult Function(
    ffi.Pointer<Utf8>, int, int, int, ffi.Pointer<Utf8>);
List<ChatMessage> chatReceive(String poolName, DateTime after, DateTime before,
    int limit, ChatPrivate private) {
  var getMessagesC =
      lib.lookupFunction<ChatReceiveC, ChatReceive>("chatReceive");
  var m = getMessagesC(
          poolName.toNativeUtf8(),
          after.microsecondsSinceEpoch,
          before.microsecondsSinceEpoch,
          limit,
          jsonEncode(private).toNativeUtf8())
      .unwrapList();

  return m.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
}

typedef ChatSend = CResult Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
int chatSend(String poolName, String contentType, String text, Uint8List binary,
    ChatPrivate private) {
  var chatSendC = lib.lookupFunction<ChatSend, ChatSend>("chatSend");

  var r = chatSendC(
      poolName.toNativeUtf8(),
      contentType.toNativeUtf8(),
      text.toNativeUtf8(),
      base64Encode(binary).toNativeUtf8(),
      jsonEncode(private).toNativeUtf8());
  return r.unwrapInt();
}

typedef ChatPrivates = CResult Function(ffi.Pointer<Utf8>);
List<ChatPrivate> chatPrivates(String poolName) {
  var fun = lib.lookupFunction<ChatPrivates, ChatPrivates>("chatPrivates");
  var m = fun(poolName.toNativeUtf8()).unwrapList();

  return m.map((e) => dynamicToList<String>(e)).toList();
}

typedef LibraryListT = CResult Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
LibraryList libraryList(String poolName, String folder) {
  var libraryListC =
      lib.lookupFunction<LibraryListT, LibraryListT>("libraryList");
  var m =
      libraryListC(poolName.toNativeUtf8(), folder.toNativeUtf8()).unwrapMap();

  return LibraryList.fromJson(m);
}

typedef LibraryFindC = CResult Function(ffi.Pointer<Utf8>, ffi.Int);
typedef LibraryFindD = CResult Function(ffi.Pointer<Utf8>, int);
LibraryFile libraryFind(String poolName, int id) {
  var fun = lib.lookupFunction<LibraryFindC, LibraryFindD>("libraryFind");
  var m = fun(poolName.toNativeUtf8(), id).unwrapMap();

  return LibraryFile.fromJson(m);
}

// librarySend(poolName *C.char, localPath *C.char, name *C.char, solveConflicts C.int, tagsList *C.char) C.Result {
typedef LibrarySendC = CResult Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>, ffi.Int, ffi.Pointer<Utf8>);
typedef LibrarySendD = CResult Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>, int, ffi.Pointer<Utf8>);
LibraryFile librarySend(String poolName, String localPath, String name,
    bool solveConflicts, List<String> tags) {
  var librarySendC =
      lib.lookupFunction<LibrarySendC, LibrarySendD>("librarySend");
  var m = librarySendC(poolName.toNativeUtf8(), localPath.toNativeUtf8(),
      name.toNativeUtf8(), solveConflicts ? 1 : 0, "[]".toNativeUtf8());
  return LibraryFile.fromJson(m.unwrapMap());
}

// libraryReceive(poolName *C.char, id C.long, localPath *C.char) C.Result
typedef LibraryReceiveC = CResult Function(
    ffi.Pointer<Utf8>, ffi.Int, ffi.Pointer<Utf8>);
typedef LibraryReceiveD = CResult Function(
    ffi.Pointer<Utf8>, int, ffi.Pointer<Utf8>);
void libraryReceive(String poolName, int id, String localPath) {
  var libraryReceiveC =
      lib.lookupFunction<LibraryReceiveC, LibraryReceiveD>("libraryReceive");
  var m =
      libraryReceiveC(poolName.toNativeUtf8(), id, localPath.toNativeUtf8());
  m.unwrapVoid();
}

// librarySave(poolName *C.char, id C.long, localPath *C.char) C.Result
typedef LibrarySaveC = CResult Function(
    ffi.Pointer<Utf8>, ffi.Int, ffi.Pointer<Utf8>);
typedef LibrarySaceD = CResult Function(
    ffi.Pointer<Utf8>, int, ffi.Pointer<Utf8>);
void librarySave(String poolName, int id, String dest) {
  var librarySaveC =
      lib.lookupFunction<LibrarySaveC, LibrarySaceD>("librarySave");
  var m = librarySaveC(poolName.toNativeUtf8(), id, dest.toNativeUtf8());
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

typedef Dump = CResult Function();
String logs() {
  var dumpC = lib.lookupFunction<Dump, Dump>("dump");
  var m = dumpC();
  return m.unwrapRaw();
}

typedef SetLogLevelC = CResult Function(ffi.Int32);
typedef SetLogLevelD = CResult Function(int);
void setLogLevel(int level) {
  var setLogLevelC =
      lib.lookupFunction<SetLogLevelC, SetLogLevelD>("setLogLevel");
  var m = setLogLevelC(level);
  m.unwrapVoid();
}
