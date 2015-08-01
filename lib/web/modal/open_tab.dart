part of upcom_api.lib.web.modal.modal;

class UpDroidOpenTabModal extends UpDroidModal {
  Function _openTab;
  Map _tabsInfo;

  UpDroidOpenTabModal(Function openTab, Map tabsInfo) {
    _openTab = openTab;
    _tabsInfo = tabsInfo;

    _setupHead('Select Tab: ');
    _setupBody();
    _setupFooter();

    _showModal();
  }

  void _setupBody() {
    DivElement selectorWrap = new DivElement()
      ..id = "selector-wrapper";
    _modalBody.children.add(selectorWrap);

    _tabsInfo.values.forEach((Map tabInfo) {
      ButtonElement tabButton = _createButton('default', tabInfo['shortName'])..onClick.listen((_) => _openTab(tabInfo));
      selectorWrap.children.add(tabButton);
    });
  }

  void _setupFooter() {
    ButtonElement discard = _createButton('warning', 'Cancel');
    _modalFooter.children.add(discard);
  }
}
