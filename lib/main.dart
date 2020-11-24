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
      TextEditingValue.fromJSON({'text': 'Username with spaces'}),
    );
    final keyset = Keyset(
      subscribeKey: SUBKEY,
      publishKey: PUBKEY,
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
                    name: e.meta['user'],
                    text: e.message['text'],
                  ),
                )
                ?.toList() ??
            [];
      });
      // Add separator
      setState(() {
        messages.add(
          ChatMessage(
            timetoken: DateTime.now().microsecondsSinceEpoch,
            name: 'History messages works fine ▲',
            text: 'But try to send new one ▼',
          ),
        );
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
                timetoken: e.timetoken.value,
                text: e.payload['text'],
                name: e.userMeta['user'],
              ),
            );
          });
        }
      });
    });
  }

  Future<int> sendMessage(String username) async {
    final result = await _pubNub.publish(
      _messagesChannel,
      {"text": "Payload works fine"},
      meta: {"user": username},
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
        title: Text('PubNub meta bug sample'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: messages.map((msg) => MessageView(msg)).toList(),
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
