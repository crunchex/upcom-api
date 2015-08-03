library upcom_api.lib.src.tab.panel;

import 'dart:async';
import 'dart:isolate';

import 'package:path/path.dart';

import 'updroid_message.dart';
import 'plugin_mailbox.dart';

abstract class Panel {
  static const String upcomName = 'upcom';

  static Future main(SendPort interfacesSendPort, List args, Function constructor) async {
    // Set up the isolate's port pair.
    ReceivePort isolatesReceivePort = new ReceivePort();
    interfacesSendPort.send(isolatesReceivePort.sendPort);

    Panel panel = constructor(interfacesSendPort, args);

    await for (var received in isolatesReceivePort) {
      panel.mailbox.receive(received);
    }
  }

  String refName, fullName, shortName, panelPath;
  int id;

  PluginMailbox mailbox;

  Panel(List names, SendPort sendPort, List args) {
    refName = names[0];
    fullName = names[1];
    shortName = names[2];

    panelPath = normalize(args[0]);
    id = args[1];

    mailbox = new PluginMailbox(sendPort, refName, id);

    // Register Panel's event handlers.
    mailbox.registerMessageHandler('CLOSE_PANEL', _closePanel);
    mailbox.registerMessageHandler('UPDATE_COLUMN', _updateColumn);

    // Register subclass' event handlers.
    registerMailbox();
  }

  void registerMailbox();
  void cleanup();

  void close() {
    cleanup();
  }

  void _closePanel(String msg) {
    Msg m = new Msg('CLOSE_PANEL', msg);
    mailbox.relay(upcomName, -1, m);
  }

  void _updateColumn(String msg) {
    mailbox.send(new Msg('UPDATE_COLUMN', msg));
  }
}