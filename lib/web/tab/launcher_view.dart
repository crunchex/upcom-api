part of upcom_api.lib.web.tab.launcher_controller;

/// [LauncherView] contains generic methods and fields that make up the visual
/// side of a Launcher.
class LauncherView extends ContainerView {

  /// Returns an initialized [LauncherView] as a [Future] given all normal constructors.
  ///
  /// Use this instead of calling the constructor directly.
  static Future<LauncherView> createLauncherView(int id, int col, String refName, String fullName, String shortName, [String externalCssPath]) {
    Completer c = new Completer();
    c.complete(new LauncherView(id, col, refName, fullName, shortName, externalCssPath));
    return c.future;
  }

  LauncherView(int id, int col, String refName, String fullName, String shortName, [String externalCssPath]) :
  super(id, col, refName, fullName, shortName, null, querySelector('#column-$col').children[0], false) {
    if (externalCssPath != null) {
      loadExternalCss(externalCssPath);
    }

    tabHandle.classes.add('launcher-handle');
    tabHandleButton.text = '$shortName';
  }
}