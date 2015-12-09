library upcom_api.lib.web.tab.panel_controller;

import 'dart:html';
import 'dart:async';
import 'dart:convert';

import '../mailbox/mailbox.dart';
//import '../menu/context_menu.dart';

part 'panel_view.dart';

abstract class PanelController {
  int id, col;
  bool active;
  String refName, fullName, shortName;

  PanelView view;
  Mailbox mailbox;

  PanelController(List<String> names, List menuConfig, [String externalCssPath]) {
    refName = names[0];
    fullName = names[1];
    shortName = names[2];
    // Wait for an ID event before we continue with the setup.
    _getId().then((_) => _setupPanel(menuConfig, externalCssPath));

    // Let UpCom know that we are ready for ID.
    CustomEvent event = new CustomEvent('PanelReadyForId', canBubble: false, cancelable: false, detail: refName);
    window.dispatchEvent(event);
  }

  Future _getId() {
    EventStreamProvider<CustomEvent> panelIdStream = new EventStreamProvider<CustomEvent>('PanelIdEvent');
    return panelIdStream.forTarget(window).where((CustomEvent e) {
      Map detail = JSON.decode(e.detail);
      return refName == detail['refName'];
    }).first.then((e) {
      Map detail = JSON.decode(e.detail);
      id = detail['id'];
      col = detail['col'];
    });
  }

  Future _setupPanel(List menuConfig, [String externalCssPath]) async {
    mailbox = new Mailbox(refName, id);
    registerMailbox();

    view = await PanelView.createPanelView(id, col, refName, fullName, shortName, menuConfig, externalCssPath);

    // TODO: set up panel-specific context menu.
//    view.tabHandleButton.onContextMenu.listen((e) {
//      e.preventDefault();
//      List menu = [
//        {'type': 'toggle', 'title': 'Clone', 'handler': _clonePanel},
//        {
//          'type': 'toggle',
//          'title': 'Move ${col == 1 ? 'Right' : 'Left'}',
//          'handler': () => _movePanelTo(col == 1 ? 2 : 1)
//        }
//      ];
//      ContextMenu.createContextMenu(e.page, menu);
//    });

    setUpController();

    mailbox.registerWebSocketEvent(EventType.ON_MESSAGE, 'UPDATE_COLUMN', _updateColumn);
    registerEventHandlers();

    // When the content of this panel receives focus, transfer it to whatever is the main content of the panel
    // (which may or may not be the direct child of view.content).
    // Also, this is done last as additional view set up may have been done in setUpController().
    view.tabContent.onFocus.listen((e) => elementToFocus.focus());

    CustomEvent event = new CustomEvent('PanelSetupComplete', canBubble: false, cancelable: false, detail: refName);
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

  Future<bool> _closePanel() async {
    // Cancel closing if preClose returns false for some reason.
    bool canClose = await preClose();
    if (!canClose) return false;

    view.destroy();
    cleanUp();

    Msg um = new Msg('CLOSE_PANEL', '$refName:$id');
    mailbox.ws.send(um.toString());

    return true;
  }

  void _updateColumn(Msg um) {
    col = int.parse(um.body);
    view.col = int.parse(um.body);
  }
}
