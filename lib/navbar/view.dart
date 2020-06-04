import 'dart:html' as html;
import 'package:dashboard/navbar/controller.dart';

const NAV_BRAND_ID = 'nav-brand';
const NAV_LINKS_WRAPPER_ID = 'nav-links-wrapper';
const NAV_ITEM_CSS_CLASSNAME = 'nav-item';
const ACTIVE_CSS_CLASSNAME = 'active';

html.SpanElement get _navBrand => html.querySelector('nav #${NAV_BRAND_ID}');
html.UListElement get _navLinksWrapper =>
    html.querySelector('nav #${NAV_LINKS_WRAPPER_ID}');
List<html.LIElement> get _navLinks => html.querySelectorAll(
    'nav #${NAV_LINKS_WRAPPER_ID} .${NAV_ITEM_CSS_CLASSNAME}');

class View {
  Controller controller;

  View(this.controller);

  void setNavBrand(String text) {
    _navBrand.innerText = text;
  }

  void appendNavLink(String pathname, String label, bool isSelected) {
    var li = html.LIElement()
      ..classes = [NAV_ITEM_CSS_CLASSNAME, if (isSelected) ACTIVE_CSS_CLASSNAME]
      ..innerText = label
      ..id = pathname
      ..onClick.listen(
          (e) => controller.command(UIAction.gotoURL, URLData(pathname)));
    _navLinksWrapper.append(li);
  }

  void setNavlinkSelected(String id) {
    for (var link in _navLinks) {
      link.classes.toggle(ACTIVE_CSS_CLASSNAME, link.getAttribute('id') == id);
    }
  }
}
