part of upcom_api.lib.web.modal.modal;

class UpDroidOpenTabModal extends UpDroidModal {
  Function _openTab;
  Map _tabsInfo;

  UpDroidOpenTabModal(Function openTab, Map tabsInfo, {bool fake}) {
    _openTab = openTab;
    _tabsInfo = tabsInfo;

    _setupHead('Select Tab: ');
    if(fake != null) _setupFakeBody();
    else {
      _setupBody();
    }
    _setupFooter();

    _showModal();
  }

  void _setupBody() {
    print("real build");
    DivElement selectorWrap = new DivElement()
      ..id = "selector-wrapper";
    _modalBody.children.add(selectorWrap);

    _tabsInfo.values.forEach((Map tabInfo) {
      ButtonElement tabButton = _createButton('default', tabInfo['shortName'])..onClick.listen((_) => _openTab(tabInfo));
      if(tabInfo['shortName'] == "Shop") {
        tabButton.id = "shop-button";
        selectorWrap.children.add(tabButton);
      }
    });

    _tabsInfo.values.forEach((Map tabInfo) {
      ButtonElement tabButton = _createButton('default', tabInfo['shortName'])..onClick.listen((_) => _openTab(tabInfo));
      if(tabInfo['shortName'] != "Shop") {
        selectorWrap.children.add(tabButton);
      }
    });
  }

  void _setupFakeBody() {
    print('fake build');
    DivElement selectorWrap = new DivElement()
      ..id = "selector-wrapper";
    _modalBody.children.add(selectorWrap);

    _tabsInfo.values.forEach((Map tabInfo) {
      ButtonElement tabButton = _createButton('default', tabInfo['shortName'])
        ..onClick.listen((_) => _openTab(tabInfo));
      if (tabInfo['shortName'] == "Shop") {
        tabButton.id = "shop-button";
        selectorWrap.children.add(tabButton);
      }
    });

    _tabsInfo.values.forEach((Map tabInfo) {
      ButtonElement tabButton = _createButton('default', tabInfo['shortName'])
        ..onClick.listen((_) => _openTab(tabInfo));
      if (tabInfo['shortName'] != "Shop" && tabInfo['shortName'] != "Teleop") {
        selectorWrap.children.add(tabButton);
      }
    });
  }

  void _setupFooter() {
    ButtonElement discard = _createButton('warning', 'Cancel');
    _modalFooter.children.add(discard);
  }
}
