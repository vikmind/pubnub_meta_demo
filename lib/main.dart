import 'package:flutter/material.dart';
import 'package:pubnub/pubnub.dart';
import 'package:pubnub_meta_demo/chat_message.dart';

void main() {
  runApp(MyApp());
}

const PUBKEY = String.fromEnvironment('PUBKEY');
const SUBKEY = String.fromEnvironment('SUBKEY');

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PubNub bug demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ChatMessage> messages = [];
  PubNub _pubNub;
  final String _messagesChannel =
      'messages_channel_' + DateTime.now().toIso8601String().substring(0, 13);
  TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController.fromValue(
      TextEditingValue.fromJSON({'text': 'New message'}),
    );
    final keyset = Keyset(
      subscribeKey: SUBKEY,
      publishKey: PUBKEY,
      uuid: UUID('user-1'),
    );
    _pubNub = PubNub(
      defaultKeyset: keyset,
    );

    // Load history first
    _pubNub.batch.fetchMessages(
      {_messagesChannel},
      includeMeta: true,
      includeMessageType: true,
      reverse: false,
    ).then((batch) {
      final historyEntries = batch.channels[_messagesChannel];
      setState(() {
        messages = historyEntries
                ?.map(
                  (e) => ChatMessage(
                    timetoken: e.timetoken.value,
                    name: e?.meta['user'] ?? '',
                    text: e.message['text'],
                  ),
                )
                ?.toList() ??
            [];
      });
      final _msgSubscription = _pubNub.subscribe(
        channels: {_messagesChannel},
        withPresence: true,
      );
      // Listen for updates
      _msgSubscription.messages.listen((e) {
        if (e.messageType == MessageType.normal) {
          setState(() {
            messages.add(
              ChatMessage(
                timetoken: e.publishedAt.value,
                text: e.payload['text'],
                name: e.userMeta['user'],
              ),
            );
          });
        }
      });
    });
  }

  Future<int> sendMessage(String message) async {
    final result = await _pubNub.publish(
      _messagesChannel,
      {"text": message},
      meta: {"user": "user-1"},
    );
    if (result.isError) {
      throw result.description;
    }
    return result.timetoken;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PubNub add action bug'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: messages
                  .map((msg) => MessageView(
                        msg,
                        action: () async {
                          await _pubNub.addMessageAction(
                            'report',
                            'report',
                            _messagesChannel,
                            Timetoken(msg.timetoken),
                          );
                        },
                      ))
                  .toList(),
            ),
          ),
          SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                  ),
                ),
                IconButton(
                  onPressed: () => sendMessage(controller.text),
                  icon: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
