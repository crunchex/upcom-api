part of upcom_api.lib.web.tab.tab_controller;

/// [UpDroidTab] contains methods to generate [Element]s that make up a tab
/// and menu bar in the UpDroid Commander GUI.
class TabView extends ContainerView {

  /// Returns an initialized [TabView] as a [Future] given all normal constructors.
  ///
  /// Use this instead of calling the constructor directly.
  static Future<TabView> createTabView(int id, int col, String refName, String fullName, String shortName, List config, [String externalCssPath]) {
    Completer c = new Completer();
    c.complete(new TabView(id, col, refName, fullName, shortName, config, externalCssPath));
    return c.future;
  }

  LIElement extra;
  DivElement closeControlHitbox;

  TabView(int id, int col, String refName, String fullName, String shortName, List config, [String externalCssPath]) :
  super(id, col, refName, fullName, shortName, config, querySelector('#column-$col').children[0]) {
    if (externalCssPath != null) {
      loadExternalCss(externalCssPath);
    }

    tabHandleButton.text = '$shortName-$id';

    extra = new LIElement();
    extra.id = 'extra-$id';
    extra.classes.add('extra-menubar');
    menus.children.add(extra);

    closeControlHitbox = new DivElement()
      ..title = 'Close'
      ..classes.add('close-control-hitbox');
    tabHandle.children.insert(0, closeControlHitbox);

    DivElement closeControl = new DivElement()
      ..classes.addAll(['close-control', 'glyphicons', 'glyphicons-remove-2']);
    closeControlHitbox.children.add(closeControl);
  }
}