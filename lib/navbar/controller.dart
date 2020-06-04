import 'package:dashboard/logger.dart';
import 'package:dashboard/navbar/view.dart' as nav_view;
import 'package:dashboard/model.dart' as model;
import 'package:dashboard/utils.dart' as utils;

Logger logger = Logger('navbar/controller.dart');

enum UIAction { gotoURL }

class Data {}

class URLData extends Data {
  String pathname;
  URLData(this.pathname);
}

class Controller {
  nav_view.View _view;
  final List<model.Link> _links;

  Controller(this._links) {
    _view = nav_view.View(this);
    _initialRender();
  }

  void _initialRender() {
    for (var link in _links) {
      _view.appendNavLink(
          link.pathname, link.label, link.pathname == utils.currentPathname);
    }
  }

  void command(UIAction action, Data data) {
    switch (action) {
      case UIAction.gotoURL:
        URLData url = data;
        utils.gotoPath(url.pathname);
        _view.setNavlinkSelected(url.pathname);
        break;
      default:
    }
  }
}
