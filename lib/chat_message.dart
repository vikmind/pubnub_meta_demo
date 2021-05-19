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
  final VoidCallback action;

  const MessageView(
    this.message, {
    Key key,
    this.action,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(child: Text(message.text)),
          IconButton(
            icon: Icon(Icons.report),
            onPressed: action,
          )
        ],
      ),
    );
  }
}
