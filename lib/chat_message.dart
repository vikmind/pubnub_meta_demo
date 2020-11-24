import 'package:flutter/material.dart';

class ChatMessage {
  final String name;
  final String text;
  final int timetoken;

  const ChatMessage({
    this.timetoken,
    this.text,
    this.name,
  });
}

class MessageView extends StatelessWidget {
  final ChatMessage message;

  const MessageView(this.message, {Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            'Name: ${message.name}',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(message.text),
        ],
      ),
    );
  }
}

