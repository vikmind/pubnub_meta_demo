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
  List<ChatMessage> _messages = [];
  PubNub _pubNub;
  final String _messagesChannel =
      'messages_channel_' + DateTime.now().toIso8601String().substring(0, 13);
  TextEditingController _controller;
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController.fromValue(
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
        _messages = historyEntries
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
            _messages.add(
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

  void _addAction(int timetoken) {
    _pubNub
        .addMessageAction(
      'report',
      'report',
      _messagesChannel,
      Timetoken(timetoken),
    )
        .catchError(
      (e) {
        setState(() => _errors.add(e.toString()));
      },
    );
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
              children: _messages
                  .map((msg) => MessageView(
                        msg,
                        action: () => _addAction(msg.timetoken),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView(
              children: _errors.map((e) => Text(e)).toList(),
            ),
          ),
          SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                  ),
                ),
                IconButton(
                  onPressed: () => sendMessage(_controller.text),
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
