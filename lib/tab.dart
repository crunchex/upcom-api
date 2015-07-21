library tab;

import 'dart:async';
import 'dart:isolate';

import 'updroid_message.dart';
import 'server_message.dart';
import 'tab_mailbox.dart';

abstract class Tab {
  static Future main(SendPort interfacesSendPort, List args, Function constructor) async {
    // Set up the isolate's port pair.
    ReceivePort isolatesReceivePort = new ReceivePort();
    interfacesSendPort.send(isolatesReceivePort.sendPort);

    int id = args[0];
    String path = args[1];
    Tab tab = constructor(id, path, interfacesSendPort, args);

    await for (var received in isolatesReceivePort) {
      tab.mailbox.receive(received);
    }
  }

  int id;
  String guiName;

  TabMailbox mailbox;

  Tab(this.id, this.guiName, SendPort sendPort) {
    mailbox = new TabMailbox(sendPort);

    // Register Tab's event handlers.
    mailbox.registerMessageHandler('CLOSE_TAB', _closeTab);
    mailbox.registerMessageHandler('CLONE_TAB', _cloneTab);
    mailbox.registerMessageHandler('MOVE_TAB', _moveTab);

    // Register subclass' event handlers.
    registerMailbox();
  }

  void registerMailbox();
  void cleanup();

  void close() {
    cleanup();
  }

  void _closeTab(String msg) {
    Msg m = new Msg('CLOSE_TAB', msg);
    mailbox.relay(new ServerMessage('UpDroidClient', -1, m));
  }

  void _cloneTab(String msg) {
    Msg m = new Msg('CLONE_TAB', msg);
    mailbox.relay(new ServerMessage('UpDroidClient', -1, m));
  }

  void _moveTab(String msg) {
    Msg m = new Msg('MOVE_TAB', msg);
    mailbox.relay(new ServerMessage('UpDroidClient', -1, m));
  }
}