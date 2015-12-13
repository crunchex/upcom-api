library upcom_api.lib.web.tab.tab_controller;

import 'dart:html';
import 'dart:async';
import 'dart:convert';

import 'package:upcom-api/web/mailbox/mailbox.dart';
import 'package:upcom-api/web/menu/context_menu.dart';
import 'package:upcom-api/web/menu/plugin_menu.dart' as PluginMenu;

enum PluginType { TAB, PANEL }

abstract class TabController {
  int id, col;
  bool active, contextMenuEnabled, closeButtonEnabled;
  String refName, fullName, shortName;
  PluginType type;

  DivElement tabHandle, tabContainer, tabContent, content, closeButton;
  AnchorElement tabHandleButton;
  UListElement menus;
  Mailbox mailbox;

  List<StreamSubscription> _listeners;

  TabController(List<String> names, this.contextMenuEnabled, this.closeButtonEnabled, [List config]) {
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

  Future _getId() {
    String url = window.location.host.split(':')[0];
    return HttpRequest.getString('http://' + url + ':12060/upcom/requestId/$refName');
  }

  void _generateMenu(List config) {
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

  void _setUpTab([List config]) {
    DivElement columnContent = querySelector('#column-$col');
    type = (columnContent.classes.contains('col-xs-2')) ? PluginType.PANEL : PluginType.TAB;

    tabHandle = querySelector('#tab-$refName-$id-handle');

    if (closeButtonEnabled) {
      closeButton = tabHandle.children.first;
      tabHandleButton = tabHandle.children[1];
    } else {
      tabHandleButton = tabHandle.children.first;
    }

    tabContainer = querySelector('#tab-$refName-$id-container');
    tabContent = tabContainer.children[0];
    content = tabContent.children[0];

    if (config != null) _generateMenu(config);

    mailbox = new Mailbox(refName, id);
    registerMailbox();

    setUpController();

    mailbox.registerWebSocketEvent(EventType.ON_MESSAGE, 'UPDATE_COLUMN', _updateColumn);

    _registerEventHandlers();
  }

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

    if (closeButtonEnabled) {
      _listeners.add(closeButton.onClick.listen((e) => _closeTab()));
    }

    if (contextMenuEnabled) {
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

    // Child event handlers.
    registerEventHandlers();
  }

  void _cloneTab() => mailbox.ws.send(new Msg('CLONE_TAB', '$refName:$col').toString());
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
