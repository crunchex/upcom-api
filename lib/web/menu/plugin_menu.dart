library upcom_api.lib.web.menu.plugin_menu;

import 'dart:html';

LIElement addMenuItem(int id, String refName, Map itemConfig, Map refMap, [String dropdownMenuSelector]) {
  String type = itemConfig['type'];
  String title = itemConfig['title'];
  String handler = itemConfig['handler'];
  var args = itemConfig['args'];
  List<String> items = itemConfig['items'];

  LIElement itemElement;
  switch (type) {
    case 'toggle':
      itemElement = createToggleItem(title, handler, args, refMap);
      break;
    case 'input':
      itemElement = createInputItem(title, refMap);
      break;
    case 'submenu':
      itemElement = createSubMenu(id, refName, title, items, refMap);
      break;
    case 'divider':
      itemElement = createDivider(title);
      break;
  }

  if (dropdownMenuSelector != null) {
    querySelector(dropdownMenuSelector).children.add(itemElement);
  }

  return itemElement;
}

/// Generates a dropdown menu and returns the new [LIElement].
LIElement createDropdownMenu(int id, String refName, Map config, Map refMap) {
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
  dropdown.children.add(dropdownToggle);
  refMap[title] = dropdownToggle;

  UListElement dropdownMenu = new UListElement()
    ..id = '$refName-$id-$sanitizedTitle'
    ..classes.add('dropdown-menu')
    ..attributes['role'] = 'menu';
  dropdown.children.add(dropdownMenu);

  LIElement item;
  for (Map i in items) {
    item = addMenuItem(id, refName, i, refMap);
    dropdownMenu.children.add(item);
  }

  return dropdown;
}

/// Generates a toggle item (button) and returns the new [LIElement].
LIElement createDivider(String title) {
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
LIElement createSubMenu(int id, String refName, String title, List<String> items, Map refMap) {
  String sanitizedTitle =
  title.toLowerCase().replaceAll('.', '').replaceAll(' ', '-');
  String sanitizedId = '$refName-$id-$sanitizedTitle';

  LIElement item = new LIElement()..classes.add('dropdown-submenu');
  AnchorElement button = new AnchorElement()
    ..tabIndex = -1
    ..href = '#'
    ..text = title;
  item.append(button);
  refMap[title] = button;
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
    refMap[item] = inner;
    menuItem.append(inner);
    dropdown.append(menuItem);
  }
  return item;
}

/// Generates an input item (label and input field) and returns
/// the new [LIElement].
LIElement createInputItem(String title, Map refMap) {
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

  return li;
}

/// Generates a toggle item (button) and returns the new [LIElement].
LIElement createToggleItem(String title, onClick, args, Map refMap) {
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

  refMap[title] = button;

  buttonList.children.add(button);

  return buttonList;
}
