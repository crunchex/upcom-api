library upcom_api.lib.src.tab.tab;

import 'dart:async';
import 'dart:isolate';

import 'package:path/path.dart';

import 'updroid_message.dart';
import 'tab_mailbox.dart';

abstract class Tab {
  static const String upcomName = 'upcom';

  static Future main(SendPort interfacesSendPort, List args, Function constructor) async {
    // Set up the isolate's port pair.
    ReceivePort isolatesReceivePort = new ReceivePort();
    interfacesSendPort.send(isolatesReceivePort.sendPort);

    Tab tab = constructor(interfacesSendPort, args);

    await for (var received in isolatesReceivePort) {
      tab.mailbox.receive(received);
    }
  }

  String refName, fullName, shortName, tabPath;
  int id;

  TabMailbox mailbox;

  Tab(List names, SendPort sendPort, List args) {
    refName = names[0];
    fullName = names[1];
    shortName = names[2];

    tabPath = normalize(args[0]);
    id = args[1];

    mailbox = new TabMailbox(sendPort, refName, id);

    // Register Tab's event handlers.
    mailbox.registerMessageHandler('CLOSE_TAB', _closeTab);
    mailbox.registerMessageHandler('CLONE_TAB', _cloneTab);
    mailbox.registerMessageHandler('MOVE_TAB', _moveTab);
    mailbox.registerMessageHandler('UPDATE_COLUMN', _updateColumn);

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
    mailbox.relay(upcomName, -1, m);
  }

  void _cloneTab(String msg) {
    Msg m = new Msg('CLONE_TAB', msg);
    mailbox.relay(upcomName, -1, m);
  }

  void _moveTab(String msg) {
    Msg m = new Msg('MOVE_TAB', msg);
    mailbox.relay(upcomName, -1, m);
  }

  void _updateColumn(String msg) {
    mailbox.send(new Msg('UPDATE_COLUMN', msg));
  }
}