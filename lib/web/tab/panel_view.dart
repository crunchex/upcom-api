part of upcom_api.lib.web.tab.panel_controller;

/// [PanelView] contains generic methods and fields that make up the visual
/// side of a Panel.
class PanelView extends ContainerView {

  /// Returns an initialized [PanelView] as a [Future] given all normal constructors.
  ///
  /// Use this instead of calling the constructor directly.
  static Future<PanelView> createPanelView(int id, int col, String refName, String fullName, String shortName, List config, [String externalCssPath]) {
    Completer c = new Completer();
    c.complete(new PanelView(id, col, refName, fullName, shortName, config, externalCssPath));
    return c.future;
  }

  DivElement closeControlHitbox;

  PanelView(int id, int col, String refName, String fullName, String shortName, List config, [String externalCssPath]) :
  super(id, col, refName, fullName, shortName, config, querySelector('#column-$col').children[0]) {
    if (externalCssPath != null) {
      loadExternalCss(externalCssPath);
    }

    tabHandleButton.text = '$shortName';

    closeControlHitbox = new DivElement()
      ..title = 'Close'
      ..classes.add('close-control-hitbox');
    tabHandle.children.insert(0, closeControlHitbox);

    DivElement closeControl = new DivElement()
      ..classes.addAll(['close-control', 'glyphicons', 'glyphicons-remove-2']);
    closeControlHitbox.children.add(closeControl);
  }
}