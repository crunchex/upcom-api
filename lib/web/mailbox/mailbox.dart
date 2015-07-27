library mailbox;

import 'dart:html';
import 'dart:async';

part 'updroid_message.dart';

enum EventType { ON_OPEN, ON_MESSAGE, ON_CLOSE }

/// A class to initialize its owning class' main [WebSocket] connection to the
/// server side. It also manages all incoming messages over [WebSocket] and, if provided,
/// [CommanderMessage] stream.
class Mailbox {
  String _name;
  int _id;
  WebSocket ws;

  Map _wsRegistry;
  Set<String> _waitForRegistry;

  Mailbox(String name, int num) {
    _name = name;
    _id = num;

    _wsRegistry = { EventType.ON_OPEN: [], EventType.ON_MESSAGE: {}, EventType.ON_CLOSE: [] };
    _waitForRegistry = new Set();

    // Create the server <-> client [WebSocket].
    // Port 12060 is the default port that UpDroid uses.
    String url = window.location.host.split(':')[0];
    _initWebSocket(url);
  }

  /// Returns a [Future] [UpDroidMessage] as a response from the server when given a
  /// request [UpDroidMessage]. Useful for simple HTTP GET-type requests over having to
  /// register a whole event handler.
  ///
  /// Note: an [UpDroidMessage] header given to the waitFor registry takes precedence
  /// over any equivalent header registered as an on-message event handler. Also, waitFor
  /// will not allow duplicate headers registered at any one time.
  Future<Msg> waitFor(Msg out) async {
    _waitForRegistry.add(out.header);
    ws.send(out.toString());

    // Execution pauses here until an UpDroid Message with a matching header is received.
    Msg received = await ws.onMessage.transform(Msg.toMsg).firstWhere((Msg um) => um.header == out.header);
    _waitForRegistry.remove(out.header);
    return received;
  }

  /// Registers a [function] to be called on one of the [WebSocket] events.
  /// If registering for ON_MESSAGE, [msg] is required to know which function to call.
  void registerWebSocketEvent(EventType type, String msg, function(Msg um)) {
    if (type == EventType.ON_MESSAGE) {
      _wsRegistry[type][msg] = function;
      return;
    }

    _wsRegistry[type].add(function);
  }

  void _initWebSocket(String url, [int retrySeconds = 2]) {
    bool encounteredError = false;

    ws = new WebSocket('ws://' + url + ':12060/${_name}/$_id');

    // Call all the functions registered to ON_OPEN.
    ws.onOpen.listen((e) => _wsRegistry[EventType.ON_OPEN].forEach((f(e)) => f(e)));

    // Call the function registered to ON_MESSAGE[um.header].
    ws.onMessage.transform(Msg.toMsg)
    .where((Msg um) => !_waitForRegistry.contains(um.header))
    .listen((Msg um) {
      //print('[${_name}\'s Mailbox] UpDroidMessage received of type: ${um.header}');
      if (_wsRegistry[EventType.ON_MESSAGE].containsKey(um.header)) {
        _wsRegistry[EventType.ON_MESSAGE][um.header](um);
      } else {
        //print('[${_name}\'s Mailbox] UpDroidMessage received of type: ${um.header}, but no handler registered.');
      }
    });

    // Disabled auto-reconnect until we can detect whether a crash is occurred, in which case
    // everything needs to be restarted, or the connection has temporarily dropped.
    ws.onClose.listen((e) {
      _wsRegistry[EventType.ON_CLOSE].forEach((f(e)) => f(e));

      //print('$_name-$_id disconnected. Retrying...');
//      if (!encounteredError) {
//        new Timer(new Duration(seconds:retrySeconds), () => _initWebSocket(url, retrySeconds * 2));
//      }
//      encounteredError = true;
    });

//    ws.onError.listen((e) {
//      //print('$_name-$_id disconnected. Retrying...');
//      if (!encounteredError) {
//        new Timer(new Duration(seconds:retrySeconds), () => _initWebSocket(url, retrySeconds * 2));
//      }
//      encounteredError = true;
//    });
  }
}