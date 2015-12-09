library upcom_api.lib.web.tab.tab_controller;

import 'dart:html';
import 'dart:async';
import 'dart:convert';

import 'package:upcom-api/web/mailbox/mailbox.dart';
import 'package:upcom-api/web/menu/context_menu.dart';
import 'package:upcom-api/web/menu/plugin_menu.dart' as PluginMenu;

enum PluginType { TAB, PANEL, LAUNCHER }

abstract class TabController {
  int id, col;
  bool active;
  String refName, fullName, shortName;
  PluginType type;

  DivElement tabHandle, tabContainer, tabContent, content, closeButton;
  AnchorElement tabHandleButton;
  UListElement menus;
  Mailbox mailbox;

  List<StreamSubscription> _listeners;

  TabController(List<String> names, this.type, [List config]) {
    refName = names[0];
    fullName = names[1];
    shortName = names[2];

    _getId().then((idFromServer) {
      List<int> idList = JSON.decode(idFromServer);
      id = idList[0];
      col = idList[1];
      _setUpTab(config);
    });
  }

  Future _getId() {
    String url = window.location.host.split(':')[0];
    return HttpRequest.getString('http://' + url + ':12060/upcom/requestId/$refName');
  }

  void _setUpTab([List config]) {
    tabHandle = querySelector('#tab-$refName-$id-handle');
    tabHandleButton = tabHandle.children[(type == PluginType.TAB) ? 1 : 0];

    tabContainer = querySelector('#tab-$refName-$id-container');
    tabContent = tabContainer.children[0];
    content = tabContent.children[0];

    if (type == PluginType.TAB) {
      closeButton = tabHandle.children.first;

      if (config != null) {
        menus = new UListElement()
          ..classes.add('nav')
          ..classes.add('nav-tabs')
          ..classes.add('inner-tabs')
          ..attributes['role'] = 'tablist';

        menus.children = new List<Element>();
        for (Map configItem in config) {
          menus.children.add(PluginMenu.createDropdownMenu(id, refName, configItem));
        }

        tabContainer.children.insert(0, menus);
      }
    }

    mailbox = new Mailbox(refName, id);
    registerMailbox();

    setUpController();

    mailbox.registerWebSocketEvent(EventType.ON_MESSAGE, 'UPDATE_COLUMN', _updateColumn);

    // Super event handlers.
    _registerEventHandlers();
    // Child event handlers.
    registerEventHandlers();
}

  /// Adds the CSS classes to make a tab 'active'.
  void makeActive() {
    tabHandle.classes.add('active');
    tabContainer.classes.add('active');
  }

  /// Removes the CSS classes to make a tab 'inactive'.
  void makeInactive() {
    tabHandle.classes.remove('active');
    tabContainer.classes.remove('active');
  }

  String get hoverText => tabHandle.title;

  void set hoverText(String text) {
    tabHandle.title = text;
  }

  void registerMailbox();
  void setUpController();
  void registerEventHandlers();
  Future<bool> preClose();
  void cleanUp();
  Element get elementToFocus;

  // Private stuff.

  void _registerEventHandlers() {
    if (_listeners == null) _listeners = [];

    _listeners.add(tabHandleButton.onClick.listen((e) {
      // Need to show the tab content before the input field can be focused.
      new Timer(new Duration(milliseconds: 500), () => elementToFocus.focus());
    }));
    // When the content of this Tab receives focus, transfer it to whatever is the main content of the Tab
    // (which may or may not be the direct child of view.content).
    // Also, this is done last as additional view set up may have been done in setUpController().
    _listeners.add(tabContent.onFocus.listen((e) => elementToFocus.focus()));

    if (type != PluginType.TAB) return;
    _listeners.add(closeButton.onClick.listen((e) => _closeTab()));
    _listeners.add(tabHandleButton.onContextMenu.listen((e) {
      e.preventDefault();
      List menu = [
        {'type': 'toggle', 'title': 'Clone', 'handler': _cloneTab},
        {
           'type': 'toggle',
           'title': 'Move ${col == 1 ? 'Right' : 'Left'}',
           'handler': () => _moveTabTo(col == 1 ? 2 : 1)
        }];
      ContextMenu.createContextMenu(e.page, menu);
    }));
  }

  void _cloneTab() => mailbox.ws.send(new Msg('CLONE_TAB', '$refName:$id:$col').toString());
  void _moveTabTo(int newCol) => mailbox.ws.send(new Msg('MOVE_TAB', '$refName:$id:$col:$newCol').toString());

  Future<bool> _closeTab() async {
    // Cancel closing if preClose returns false for some reason.
    bool canClose = await preClose();
    if (!canClose) return false;

    for (StreamSubscription sub in _listeners) {
      sub.cancel();
    }

    cleanUp();

    Msg um = new Msg('CLOSE_TAB', '$refName:$id');
    mailbox.ws.send(um.toString());

    return true;
  }

  void _updateColumn(Msg um) {
    col = int.parse(um.body);
  }
}
