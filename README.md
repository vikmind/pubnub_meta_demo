# PubNub meta encoding bug demo

Meta info sending with payload from dart code appears
to be not properly decoded by the transmitting server.

At the same time, messages fetched as history does not have such problem.

![Screenshot](https://raw.githubusercontent.com/vikmind/pubnub_meta_demo/master/assets/screenshot.png)

## Getting Started

PubNub keys were used with default `Demo` config.
Example project is started with command:

```dart
flutter run \
  --dart-define=PUBKEY="Publish PubNub key" \
  --dart-define=SUBKEY="Subscribe PubNub key"
```