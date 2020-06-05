import 'dart:html' as html;

const LOCATION_EVENT_NAME = 'locationChanged';

String get currentName => html.window.location.pathname;

void goto(String pathname, {bool replace = false}) {
  if (html.window.location.pathname == pathname) return;

  if (replace) {
    html.window.history.replaceState({}, '', pathname);
  } else {
    html.window.history.pushState({}, '', pathname);
  }

  html.window.dispatchEvent(html.Event(LOCATION_EVENT_NAME));
}

void listenToChanges(void Function(html.Event) callback) {
  html.window.addEventListener(LOCATION_EVENT_NAME, callback);
  html.window.onPopState.listen(callback);
}
