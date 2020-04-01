import 'dart:html' as html;
import 'firebase.dart' as fb;
import 'model.dart' as model;
import 'utils.dart' as util;

DateTime _STARTDATE = DateTime(2020, 3, 13);
const ALL_THEME_TAG = 'all';
enum sortOrder { asc, dsc }

html.DivElement get timelineWrapper => html.querySelector('#messages-timeline');
html.SelectElement get themeSelect => html.querySelector('#theme-select');
html.SelectElement get sortSelect => html.querySelector('#sort-select');

class App {
  List<model.Message> _messages;
  sortOrder _sortBy;
  String _selectedTheme;
  Set<String> _themes;

  App() {
    _init();
  }

  void _init() async {
    await fb.init();
    _sortBy = sortOrder.dsc;
    _messages = await fb.readMessages();
    _messages.removeWhere((m) => m.received_at.isBefore(_STARTDATE));
    _sortMessage(_sortBy);

    _themes = {};
    _messages.forEach((m) => m.tags.forEach((t) => _themes.add(t)));
    _selectedTheme = ALL_THEME_TAG;

    _addThemesSelect();
    _renderMessages();

    themeSelect.onChange.listen(_handleFilter);
    sortSelect.onChange.listen(_handleSort);
  }

  void _handleFilter(html.Event evt) {
    _selectedTheme = (evt.currentTarget as html.SelectElement).value;
    _renderMessages();
  }

  void _handleSort(html.Event evt) {
    var value = (evt.currentTarget as html.SelectElement).value;
    switch (value) {
      case 'asc':
        _sortMessage(sortOrder.asc);
        break;
      case 'dsc':
        _sortMessage(sortOrder.dsc);
        break;
    }

    _renderMessages();
  }

  void _sortMessage(sortOrder order) {
    var sign = 0;
    switch (order) {
      case sortOrder.asc:
        sign = 1;
        break;
      case sortOrder.dsc:
        sign = -1;
        break;
    }
    _messages.sort((a, b) => sign * a.received_at.compareTo(b.received_at));
  }

  void _addThemesSelect() {
    for (var t in _themes) {
      var option = html.OptionElement()
        ..value = t
        ..innerText = util.metadata[t].label;
      themeSelect.append(option);
    }
  }

  html.DivElement _getMessageRow(model.Message message) {
    var row = html.DivElement()..classes = ['row'];
    var colLeft = html.DivElement()
      ..classes = ['col-lg-2', 'col-md-6', 'col-6', 'timeline-col'];
    var colRight = html.DivElement()
      ..classes = ['col-lg-6', 'col-md-6', 'col-6'];

    var messageBox = html.DivElement()..classes = ['message-box'];

    var messageText = html.DivElement()..innerText = message.text;
    messageBox.append(messageText);

    if (message.translated_text != null) {
      var translatedText = html.DivElement()
        ..classes = ['message-translated']
        ..innerText = message.translated_text;
      messageBox.append(translatedText);
    }

    colRight.append(messageBox);

    var timeBox = html.DivElement()
      ..classes = ['message-time']
      ..innerText = util.messageTimeFormat(message.received_at);
    colLeft.append(timeBox);

    return row..append(colLeft)..append(colRight);
  }

  void _renderMessages() {
    timelineWrapper.children.clear();

    var displayMessages = List<model.Message>.from(_messages);
    if (_selectedTheme != ALL_THEME_TAG) {
      displayMessages.removeWhere((m) => !m.tags.contains(_selectedTheme));
    }

    displayMessages.forEach((m) => {timelineWrapper.append(_getMessageRow(m))});
  }
}
