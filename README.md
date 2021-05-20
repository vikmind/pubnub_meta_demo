# PubNub addMessageAction problem demo

Steps to reproduce:

1. Send a message
2. Tap on the exclamation mark sign to add action.
3. `PubNubException: 400 error: No JSON payload`

```dart
_pubNub.addMessageAction(
  'report',
  'report',
  _messagesChannel,
  Timetoken(timetoken),
);
```

![Screenshot](https://raw.githubusercontent.com/vikmind/pubnub_meta_demo/master/assets/screenshot.png)

## Getting Started

PubNub keys were used with default `Demo` config.
Example project is started with command:

```dart
flutter run \
  --dart-define=PUBKEY="Publish PubNub key" \
  --dart-define=SUBKEY="Subscribe PubNub key"
```
