library tab_controller;

import 'dart:html';
import 'dart:async';
import 'dart:convert';

import 'container_view.dart';
import '../mailbox/mailbox.dart';
import '../menu/context_menu.dart';

part 'tab_view.dart';

abstract class TabController {
  int id, col;
  bool active;
  String refName, fullName, shortName;

  TabView view;
  Mailbox mailbox;

  AnchorElement _closeTabButton;

  TabController(List<String> names, List menuConfig,
      [String externalCssPath]) {
    refName = names[0];
    fullName = names[1];
    shortName = names[2];
    // Wait for an ID event before we continue with the setup.
    _getId().then((_) => _setupTab(menuConfig, externalCssPath));

    // Let UpCom know that we are ready for ID.
    CustomEvent event = new CustomEvent('TabReadyForId',
        canBubble: false, cancelable: false, detail: refName);
    window.dispatchEvent(event);
  }

  Future _getId() {
    EventStreamProvider<CustomEvent> tabIdStream =
        new EventStreamProvider<CustomEvent>('TabIdEvent');
    return tabIdStream.forTarget(window).where((CustomEvent e) {
      Map detail = JSON.decode(e.detail);
      return refName == detail['refName'];
    }).first.then((e) {
      Map detail = JSON.decode(e.detail);
      id = detail['id'];
      col = detail['col'];
    });
  }

  Future _setupTab(List menuConfig, [String externalCssPath]) async {
    mailbox = new Mailbox(refName, id);
    registerMailbox();

    view = await TabView.createTabView(
        id, col, refName, fullName, shortName, menuConfig, externalCssPath);

    _closeTabButton = view.refMap['close-tab'];
    _closeTabButton.onClick.listen((e) => _closeTab());
    view.closeControlHitbox.onClick.listen((e) => _closeTab());

    view.tabHandleButton.onContextMenu.listen((e) {
      e.preventDefault();
      List menu = [
        {'type': 'toggle', 'title': 'Clone', 'handler': _cloneTab},
        {
          'type': 'toggle',
          'title': 'Move ${col == 1 ? 'Right' : 'Left'}',
          'handler': () => _moveTabTo(col == 1 ? 2 : 1)
        }
      ];
      ContextMenu.createContextMenu(e.page, menu);
    });

    setUpController();

    mailbox.registerWebSocketEvent(
        EventType.ON_MESSAGE, 'UPDATE_COLUMN', _updateColumn);
    registerEventHandlers();

    // When the content of this tab receives focus, transfer it to whatever is the main content of the tab
    // (which may or may not be the direct child of view.content).
    // Also, this is done last as additional view set up may have been done in setUpController().
    view.tabContent.onFocus.listen((e) => elementToFocus.focus());

    CustomEvent event = new CustomEvent('TabSetupComplete',
        canBubble: false, cancelable: false, detail: refName);
    window.dispatchEvent(event);

    return null;
  }

  void makeActive() => view.makeActive();
  void makeInactive() => view.makeInactive();

  String get hoverText => view.tabHandle.title;

  void set hoverText(String text) {
    view.tabHandle.title = text;
  }

  void registerMailbox();
  void setUpController();
  void registerEventHandlers();
  Future<bool> preClose();
  void cleanUp();
  Element get elementToFocus;

  Future<bool> _closeTab() async {
    // Cancel closing if preClose returns false for some reason.
    bool canClose = await preClose();
    if (!canClose) return false;

    view.destroy();
    cleanUp();

    Msg um = new Msg('CLOSE_TAB', '$refName:$id');
    mailbox.ws.send(um.toString());

    return true;
  }

  void _cloneTab() =>
      mailbox.ws.send(new Msg('CLONE_TAB', '$refName:$id:$col').toString());
  void _moveTabTo(int newCol) => mailbox.ws
      .send(new Msg('MOVE_TAB', '$refName:$id:$col:$newCol').toString());

  void _updateColumn(Msg um) {
    col = int.parse(um.body);
    view.col = int.parse(um.body);
  }
}
