import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:caspian/navigation/bar.dart';
import 'package:caspian/safepool/safepool.dart' as sp;
import 'package:flutter/material.dart';
import 'package:chatview/chatview.dart' as cv;
import 'package:caspian/apps/chat/theme.dart';

class Chat extends StatefulWidget {
  const Chat({Key? key}) : super(key: key);

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  AppTheme theme = LightTheme();
  DateTime _after = DateTime.fromMicrosecondsSinceEpoch(0);
  DateTime _before = DateTime.fromMicrosecondsSinceEpoch(0);
  String _poolName = "";
  late cv.ChatUser _currentUser;
  late cv.ChatController _chatController;

  Timer? timer;
  DateTime _lastMessage = DateTime.now();
  final Set<int> _sentMessages = {};

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(
      const Duration(seconds: 5),
      (Timer t) {
        var diff = DateTime.now().difference(_lastMessage).inSeconds;
        if (diff < 20 || diff > 50) {
          loadMoreMessages();
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  void initController() {
    final chatUsers = sp
        .poolUsers(_poolName)
        .map((e) => cv.ChatUser(
              id: e.id(),
              name: e.nick,
            ))
        .toList();
    _chatController = cv.ChatController(
      initialMessageList: <cv.Message>[],
      scrollController: ScrollController(),
      chatUsers: chatUsers,
    );
  }

  void loadMoreMessages() {
    _before = DateTime.now();
    var messages = sp.chatReceive(_poolName, _after, _before, 100);
    if (messages.isNotEmpty) {
      setState(() {
        _chatController.loadMoreData(messages
            .map((e) {
              switch (e.contentType) {
                case 'text/html':
                  return cv.Message(
                    id: e.id,
                    message: e.text,
                    createdAt: e.time,
                    sendBy: e.author,
                  );
                default:
                  return cv.Message(
                    id: e.id,
                    message: "unsupported content ${e.contentType}",
                    createdAt: e.time,
                    sendBy: e.author,
                    messageType: cv.MessageType.text,
                  );
              }
            })
            .where((e) => !_sentMessages.contains(int.parse(e.id)))
            .toList());
        _after = messages.last.time;
        _lastMessage = DateTime.now();
      });
    }
  }

  void setUser() {
    var p = sp.poolGet(_poolName);
    _currentUser = cv.ChatUser(id: p.self.id(), name: p.self.nick);
  }

  @override
  Widget build(BuildContext context) {
    final poolName = ModalRoute.of(context)!.settings.arguments as String;

    if (_poolName.isEmpty) {
      _poolName = poolName;

      setUser();
      initController();
      loadMoreMessages();
    }

    var chatBackgroundConfig = cv.ChatBackgroundConfiguration(
      messageTimeIconColor: theme.messageTimeIconColor,
      messageTimeTextStyle: TextStyle(color: theme.messageTimeTextColor),
      defaultGroupSeparatorConfig: cv.DefaultGroupSeparatorConfiguration(
        textStyle: TextStyle(
          color: theme.chatHeaderColor,
          fontSize: 17,
        ),
      ),
      backgroundColor: theme.backgroundColor,
    );

    var isDesktop = Platform.isMacOS || Platform.isLinux || Platform.isWindows;

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
      body: cv.ChatView(
        currentUser: _currentUser,
        chatViewState: cv.ChatViewState.hasMessages,
        chatController: _chatController,
        onSendTap: _onSendTap,
        sendMessageConfig: cv.SendMessageConfiguration(
          allowRecordingVoice: !isDesktop,
          imagePickerIconsConfig: cv.ImagePickerIconsConfiguration(
            onImageSelected: (imagePath, error) {},
            cameraIconColor: Colors.black,
            galleryIconColor: Colors.black,
          ),
          textFieldConfig: cv.TextFieldConfiguration(
            textStyle: TextStyle(color: theme.textFieldTextColor),
          ),
        ),
        chatBackgroundConfig: chatBackgroundConfig,
        chatBubbleConfig: cv.ChatBubbleConfiguration(
          outgoingChatBubbleConfig: cv.ChatBubble(
            linkPreviewConfig: cv.LinkPreviewConfiguration(
                backgroundColor: theme.linkPreviewOutgoingChatColor,
                bodyStyle: theme.outgoingChatLinkBodyStyle,
                titleStyle: theme.outgoingChatLinkTitleStyle,
                loadingColor: Colors.black54),
            color: theme.outgoingChatBubbleColor,
          ),
          inComingChatBubbleConfig: cv.ChatBubble(
            linkPreviewConfig: cv.LinkPreviewConfiguration(
              linkStyle: TextStyle(
                color: theme.inComingChatBubbleTextColor,
                decoration: TextDecoration.underline,
              ),
              backgroundColor: theme.linkPreviewIncomingChatColor,
              bodyStyle: theme.incomingChatLinkBodyStyle,
              titleStyle: theme.incomingChatLinkTitleStyle,
            ),
            textStyle: TextStyle(color: theme.inComingChatBubbleTextColor),
            senderNameTextStyle:
                TextStyle(color: theme.inComingChatBubbleTextColor),
            color: theme.inComingChatBubbleColor,
          ),
        ),
        replyPopupConfig: cv.ReplyPopupConfiguration(
          backgroundColor: theme.replyPopupColor,
          buttonTextStyle: TextStyle(color: theme.replyPopupButtonColor),
          topBorderColor: theme.replyPopupTopBorderColor,
        ),
        reactionPopupConfig: cv.ReactionPopupConfiguration(
          shadow: BoxShadow(
            color: Colors.grey.shade400,
            blurRadius: 20,
          ),
          backgroundColor: theme.reactionPopupColor,
        ),
        swipeToReplyConfig: cv.SwipeToReplyConfiguration(
          replyIconColor: theme.swipeToReplyIconColor,
        ),
      ),
      bottomNavigationBar: MainNavigationBar(poolName),
    );
  }

  void _onSendTap(
    String message,
    cv.ReplyMessage replyMessage,
  ) {
    var id = sp.postMessage(_poolName, "text/html", message, Uint8List(0));
    _sentMessages.add(id);
    _lastMessage = DateTime.now();
    _chatController.addMessage(
      cv.Message(
        id: id.toString(),
        createdAt: DateTime.now(),
        message: message,
        sendBy: _currentUser.id,
        replyMessage: replyMessage,
        messageType: cv.MessageType.text,
      ),
    );
  }
}
