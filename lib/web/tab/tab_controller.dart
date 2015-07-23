library tab_controller;

import 'dart:html';
import 'dart:async';
import 'dart:convert';

import '../mailbox/mailbox.dart';
import '../tab/container_view.dart';
import '../menu/context_menu.dart';

part 'tab_view.dart';

abstract class TabController {
  int id, col;
  bool active;
  String fullName, shortName;

  TabView view;
  Mailbox mailbox;
  AnchorElement _closeTabButton;

  TabController(this.fullName, this.shortName, List menuConfig, [String externalCssPath]) {
    // Wait an ID event before we continue with the setup.
    _getId().then((_) => _setupTab(menuConfig, externalCssPath));

    // Let UpCom know that we are ready for ID.
    String detail = fullName;
    CustomEvent event = new CustomEvent('TabReadyForId', canBubble: false, cancelable: false, detail: detail);
    window.dispatchEvent(event);
  }

  Future _getId() {
    EventStreamProvider<CustomEvent> tabIdStream = new EventStreamProvider<CustomEvent>('TabIdEvent');
    return tabIdStream.forTarget(window)
    .where((CustomEvent e) {
      Map detail = JSON.decode(e.detail);
      return fullName == detail['className'];
    }).first.then((e) {
      Map detail = JSON.decode(e.detail);
      id = detail['id'];
      col = detail['col'];
    });
  }

  Future _setupTab(List menuConfig, [String externalCssPath]) async {
    mailbox = new Mailbox(fullName, id);
    registerMailbox();

    view = await TabView.createTabView(id, col, fullName, shortName, menuConfig, externalCssPath);

    _closeTabButton = view.refMap['close-tab'];
    _closeTabButton.onClick.listen((e) => _closeTab());
    view.closeControlHitbox.onClick.listen((e) => _closeTab());

    view.tabHandleButton.onContextMenu.listen((e) {
      e.preventDefault();
      List menu = [
        {'type': 'toggle', 'title': 'Clone', 'handler': _cloneTab},
        {'type': 'toggle', 'title': 'Move ${col == 1 ? 'Right' : 'Left'}', 'handler': () => _moveTabTo(col == 1 ? 2 : 1)}];
      ContextMenu.createContextMenu(e.page, menu);
    });

    setUpController();
    registerEventHandlers();

    // When the content of this tab receives focus, transfer it to whatever is the main content of the tab
    // (which may or may not be the direct child of view.content).
    // Also, this is done last as additional view set up may have been done in setUpController().
    view.tabContent.onFocus.listen((e) => elementToFocus.focus());

    String detail = fullName;
    CustomEvent event = new CustomEvent('TabSetupComplete', canBubble: false, cancelable: false, detail: detail);
    window.dispatchEvent(event);

    return null;
  }

  void makeActive() => view.makeActive();
  void makeInactive() => view.makeInactive();

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

    UpDroidMessage um = new UpDroidMessage('CLOSE_TAB', '${fullName}_$id');
    mailbox.ws.send(um.s);

    return true;
  }

  void _cloneTab() => mailbox.ws.send('[[CLONE_TAB]]' + '${fullName}_${id}_$col');
  void _moveTabTo(int newCol) => mailbox.ws.send('[[MOVE_TAB]]' + '${fullName}_${id}_${col}_$newCol');
}