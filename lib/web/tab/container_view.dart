library upcom_api.lib.web.tab.container_view;

import 'dart:html';
import 'dart:async';

/// [ContainerView] contains methods to generate [Element]s that make up a
/// tab/panel container with a menu bar in the UpDroid Commander GUI.
abstract class ContainerView {
  final int id;
  final String refName, fullName, shortName;

  // Column value can change when a container is moved.
  int col;

  List config;
  Map refMap;

  LinkElement styleLink;
  AnchorElement tabHandleButton;
  DivElement content, tabContainer, tabContent;
  LIElement tabHandle;
  UListElement menus;

  bool _menuEnabled;

  ContainerView(this.id, this.col, this.refName, this.fullName, this.shortName,
      this.config, DivElement handles, [bool enableMenu=true]) {
    refMap = {};

    _menuEnabled = enableMenu;

    _setUpTabHandle(handles);
    _setUpTabContainer();
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

  /// Removes the tab elements from the DOM.
  void destroy() {
    tabHandle.remove();
    tabContainer.remove();
    if (styleLink != null) styleLink.remove();
  }

  void loadExternalCss(path) {
    // Inject the associated stylesheet if one exists.
    // TODO: somehow detect if it exists at runtime.
    styleLink = new LinkElement();
    styleLink.rel = 'stylesheet';
    styleLink.href = path;
    document.head.append(styleLink);
  }

  LIElement addMenuItem(Map itemConfig, [String dropdownMenuSelector]) {
    if (!_menuEnabled) {
      throw new ViewMixupError('Tried to add a menu item on a ContainerView with menus disabled.');
      return null;
    }

    String type = itemConfig['type'];
    String title = itemConfig['title'];
    String handler = itemConfig['handler'];
    var args = itemConfig['args'];
    List<String> items = itemConfig['items'];

    LIElement itemElement;
    switch (type) {
      case 'toggle':
        itemElement = _createToggleItem(title, handler, args);
        break;
      case 'input':
        itemElement = _createInputItem(title);
        break;
      case 'submenu':
        itemElement = _createSubMenu(title, items);
        break;
      case 'divider':
        itemElement = _createDivider(title);
        break;
    }

    if (dropdownMenuSelector != null) {
      querySelector(dropdownMenuSelector).children.add(itemElement);
    }

    return itemElement;
  }

  /// Takes a [num], [col], and [title] to add a new tab for the specified column.
  void _setUpTabHandle(DivElement handles) {
    tabHandle = new LIElement();
    handles.children.add(tabHandle);

    tabHandleButton = new AnchorElement();
    tabHandle.children.add(tabHandleButton);
  }

  /// Takes a [num], [col], [title], [config], and [active] to generate the
  /// menu bar and menu items for a tab. Returns a [Map] of references to
  /// the new [Element]s as a [Future].
  void _setUpTabContainer() {
    tabContainer = new DivElement()
      ..id = 'tab-$refName-$id-container'
      ..classes.add('tab-pane')
      ..classes.add('active');

    if (_menuEnabled) {
      menus = new UListElement()
        ..classes.add('nav')
        ..classes.add('nav-tabs')
        ..classes.add('inner-tabs')
        ..attributes['role'] = 'tablist';
      tabContainer.children.add(menus);

      menus.children = new List<Element>();
      for (Map configItem in config) {
        menus.children.add(_createDropdownMenu(configItem));
      }
    }

    tabContent = new DivElement()
      ..id = 'tab-$refName-$id-content'
      ..classes.add('tab-content')
      ..tabIndex = -1;
    tabContainer.children.add(tabContent);

    content = new DivElement()..classes.add(refName);
    tabContent.children.add(content);
    refMap['content'] = content;

    querySelector('#col-$col-tab-content').children.insert(0, tabContainer);
  }

  /// Generates a dropdown menu and returns the new [LIElement].
  LIElement _createDropdownMenu(Map config) {
    String title = config['title'];
    List items = config['items'];

    String sanitizedTitle = title.toLowerCase().replaceAll(' ', '-');

    LIElement dropdown = new LIElement();
    dropdown.classes.add('dropdown');

    AnchorElement dropdownToggle = new AnchorElement()
      ..href = '#'
      ..classes.add('dropdown-toggle')
      ..dataset['toggle'] = 'dropdown'
      ..text = title;
    refMap['$sanitizedTitle-dropdown'] = dropdownToggle;
    dropdown.children.add(dropdownToggle);

    UListElement dropdownMenu = new UListElement()
      ..id = '$refName-$id-$sanitizedTitle'
      ..classes.add('dropdown-menu')
      ..attributes['role'] = 'menu';
    dropdown.children.add(dropdownMenu);

    LIElement item;
    for (Map i in items) {
      item = addMenuItem(i);
      dropdownMenu.children.add(item);
    }

    return dropdown;
  }

  /// Generates a toggle item (button) and returns the new [LIElement].
  LIElement _createDivider(String title) {
    LIElement dividerList = new LIElement();

    ParagraphElement dividerTitle = new ParagraphElement()
      ..classes.add('menu-divider-title')
      ..text = title;
    dividerList.children.add(dividerTitle);

    HRElement divider = new HRElement()..classes.add('menu-divider');
    dividerList.children.add(divider);

    return dividerList;
  }

  ///Create a submenu within a dropdown
  LIElement _createSubMenu(String title, List<String> items) {
    String sanitizedTitle =
        title.toLowerCase().replaceAll('.', '').replaceAll(' ', '-');
    String sanitizedId = '$refName-$id-$sanitizedTitle';

    LIElement item = new LIElement()..classes.add('dropdown-submenu');
    AnchorElement button = new AnchorElement()
      ..tabIndex = -1
      ..href = '#'
      ..text = title;
    item.append(button);
    SpanElement dropdownIndicator = new SpanElement()
      ..classes.addAll(['glyphicons', 'glyphicons-chevron-right']);
    button.children.add(dropdownIndicator);
    UListElement dropdown = new UListElement()
      ..id = sanitizedId
      ..classes.add('dropdown-menu');
    item.append(dropdown);

    for (String item in items) {
      LIElement menuItem = new LIElement();
      AnchorElement inner = new AnchorElement()
        ..tabIndex = -1
        ..href = "#"
        ..text = item
        ..id = "${item.toLowerCase().replaceAll(' ', '-')}-button";
      menuItem.append(inner);
      dropdown.append(menuItem);
      refMap[inner.id] = inner;
    }
    return item;
  }

  /// Generates an input item (label and input field) and returns
  /// the new [LIElement].
  LIElement _createInputItem(String title) {
    String name = title.toLowerCase().replaceAll(' ', '-');

    LIElement li = new LIElement();

    DivElement d = new DivElement();
    li.children.add(d);

    ParagraphElement p = new ParagraphElement()
      ..style.display = 'inline-block'
      ..text = title;
    d.children.add(p);

    InputElement i = new InputElement()
      ..id = '$name-input'
      ..type = 'text';
    d.children.add(i);
    refMap[name] = i;

    return li;
  }

  /// Generates a toggle item (button) and returns the new [LIElement].
  LIElement _createToggleItem(String title, onClick, args) {
    String sanitizedTitle =
        title.toLowerCase().replaceAll('.', '').replaceAll(' ', '-');

    LIElement buttonList = new LIElement();
    AnchorElement button = new AnchorElement()
      ..id = 'button-$sanitizedTitle'
      ..href = '#'
      ..attributes['role'] = 'button'
      ..text = title;

    if (onClick != null) {
      button.onClick.listen((e) => args != null ? onClick(args) : onClick());
    }

    buttonList.children.add(button);
    refMap[sanitizedTitle] = button;

    return buttonList;
  }
}

class ViewMixupError extends StateError {
  ViewMixupError(String msg) : super(msg);
}
