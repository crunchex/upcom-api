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

  PanelView(int id, int col, String refName, String fullName, String shortName, List config, [String externalCssPath]) :
  super(id, col, refName, fullName, shortName, config, querySelector('#column-$col').children[0]) {
    if (externalCssPath != null) {
      loadExternalCss(externalCssPath);
    }

    tabHandle
      ..id = 'tab-$refName-$id-handle'
      ..classes.addAll(['tab-handle', 'panel-handle', 'active']);

    tabHandleButton
      ..id = 'button-$refName-$id'
      ..href = '#tab-$refName-$id-container'
      ..dataset['toggle'] = 'tab'
      ..text = '$shortName';
  }
}