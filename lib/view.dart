import 'dart:html' as html;
import 'model.dart' as model;
import 'utils.dart' as util;
import 'model.dart' as model;
import 'package:covid/controller.dart';

List<html.Element> get _navLinks => html.querySelectorAll('.nav-item');
List<html.DivElement> get _contents => html.querySelectorAll('.content');

html.DivElement get loadingModal => html.querySelector('#loading-modal');
html.DivElement get loginModal => html.querySelector('#login-modal');
html.ButtonElement get loginButton => html.querySelector('#login-button');
html.DivElement get loginError => html.querySelector('#login-error');

html.DivElement get timelineWrapper => html.querySelector('#messages-timeline');
html.SelectElement get messagesSort =>
    html.querySelector('#messages-sort-select');

List<html.RadioButtonInputElement> get analyseChooser =>
    html.querySelectorAll('.analyse-radio');
html.CheckboxInputElement get enableCompare =>
    html.querySelector('#interactions-compare');
html.DivElement get analyseThemesContent =>
    html.querySelector('#analyse-themes-content');
html.DivElement get analyseDemographicsContent =>
    html.querySelector('#analyse-demographics-content');
html.DivElement get analyseThemesFilterWrapper =>
    html.querySelector('#analyse-themes-filter-wrapper');
html.DivElement get analyseDemogFilterWrapper =>
    html.querySelector('#analyse-demographics-filter-wrapper');
html.DivElement get analyseDemogCompareWrapper =>
    html.querySelector('#analyse-demographics-compare-wrapper');

class View {
  Controller controller;

  View() {
    _listenToNavbarChanges();
    _listenToMessagesSort();

    _listenToEnableCompare();
    _listenToAnalyseChooser();
  }

  void _listenToNavbarChanges() {
    _navLinks.forEach((link) {
      link.onClick.listen((_) {
        controller.chooseTab(link.getAttribute('id'));
      });
    });
  }

  void _listenToMessagesSort() {
    messagesSort.onChange.listen((e) {
      var value = (e.currentTarget as html.SelectElement).value;
      switch (value) {
        case 'desc':
          controller.sortMessages();
          break;
        case 'asc':
          controller.sortMessages(desc: false);
          break;
        default:
          logger.error('No such sort option');
      }
      controller.renderMessages();
    });
  }

  void _listenToEnableCompare() {
    enableCompare.onChange.listen((e) {
      var enabled = (e.target as html.CheckboxInputElement).checked;
      controller.enableCompare(enabled);
    });
  }

  void _listenToAnalyseChooser() {
    analyseChooser.forEach((chooser) {
      chooser.onChange.listen((e) {
        var value = (e.currentTarget as html.RadioButtonInputElement).value;
        switch (value) {
          case 'themes':
            controller.chooseInteractionThemes();
            break;
          case 'demographics':
            controller.chooseInteractionDemographics();
            break;
          default:
            logger.error('No such analyse option');
        }
      });
    });
  }

  void _updateNavbar() {
    _navLinks.forEach((link) {
      var id = link.getAttribute('id');
      if (id == controller.visibleTabID) {
        link.classes.toggle('active', true);
      } else {
        link.classes.remove('active');
      }
    });
  }

  void _updateContent() {
    _contents.forEach((content) {
      var id = content.getAttribute('data-tab');
      if (id == controller.visibleTabID) {
        content.attributes.remove('hidden');
      } else {
        content.attributes.addAll({'hidden': 'true'});
      }
    });
  }

  void showLoginModal() {
    loginModal.removeAttribute('hidden');
  }

  void hideLoginModal() {
    loginModal.setAttribute('hidden', 'true');
  }

  void showLoginError(String errorMessage) {
    loginError
      ..removeAttribute('hidden')
      ..innerText = errorMessage;
  }

  void hideLoginError() {
    loginError.setAttribute('hidden', 'true');
  }

  void showLoading() {
    loadingModal.removeAttribute('hidden');
  }

  void hideLoading() {
    loadingModal.setAttribute('hidden', 'true');
  }

  // Messages sort & timeline
  html.DivElement _getMessageRow(model.Message message) {
    var row = html.DivElement()..classes = ['row'];
    var colLeft = html.DivElement()
      ..classes = ['col-lg-2', 'col-md-6', 'col-6', 'timeline-col'];
    var colRight = html.DivElement()
      ..classes = ['col-lg-6', 'col-md-6', 'col-6'];

    var messageBox = html.DivElement()..classes = ['message-box'];

    var messageText = html.DivElement()..innerText = message.text;
    messageBox.append(messageText);

    if (message.translation != null) {
      var translatedText = html.DivElement()
        ..classes = ['message-translated']
        ..innerText = message.translation;
      messageBox.append(translatedText);
    }

    colRight.append(messageBox);

    var timeBox = html.DivElement()
      ..classes = ['message-time']
      ..innerText = util.messageTimeFormat(message.received_at);
    colLeft.append(timeBox);

    return row..append(colLeft)..append(colRight);
  }

  void updateMessagesSort(bool desc) {
    messagesSort.value = desc ? 'desc' : 'asc';
  }

  void renderMessagesTimeline(List<model.Message> messages) {
    timelineWrapper.children.clear();

    var displayMessages = List<model.Message>.from(messages);
    displayMessages.forEach((m) => {timelineWrapper.append(_getMessageRow(m))});
  }

  // Interaction methods
  void showInteractionAnalyseTheme() {
    analyseThemesContent.removeAttribute('hidden');
    analyseDemographicsContent.setAttribute('hidden', 'true');
  }

  void showInteractionAnalyseDemographics() {
    analyseDemographicsContent.removeAttribute('hidden');
    analyseThemesContent.setAttribute('hidden', 'true');
  }

  html.DivElement _getThemeFilterRow(
      model.InteractionFilter filter,
      Map<String, String> themeFilterValues,
      Map<String, String> compareThemeFilterValues,
      List<String> activeFilters,
      bool isCompareEnabled) {
    var row = html.DivElement()..classes = ['row'];
    var checkboxCol = html.DivElement()..classes = ['col-2'];
    var dropdownCol = html.DivElement()..classes = ['col-2'];
    var compareCol = html.DivElement()..classes = ['col-2'];

    var label = html.LabelElement()
      ..text = filter.label
      ..htmlFor = filter.value;
    var checkbox = html.CheckboxInputElement()
      ..setAttribute('id', filter.value)
      ..onChange.listen((e) {
        if ((e.target as html.CheckboxInputElement).checked) {
          controller.addToActiveThemeFilters(filter.value);
        } else {
          controller.removeFromActiveFilters(filter.value);
        }
      });
    checkboxCol..append(checkbox)..append(label);

    var dropdown = html.SelectElement()
      ..setAttribute('disabled', 'true')
      ..onChange.listen((e) {
        var value = (e.target as html.SelectElement).value;
        controller.chooseInteractionThemeFilter(filter.value, value);
      });

    var compare = html.SelectElement()
      ..setAttribute('value', 'all')
      ..setAttribute('disabled', 'true')
      ..onChange.listen((e) {
        var value = (e.target as html.SelectElement).value;
        controller.chooseInteractionCompareThemeFilter(filter.value, value);
      });

    filter.options.forEach((o) {
      var option = html.OptionElement()
        ..setAttribute('value', o.value)
        ..appendText(o.label);
      if (o.value == themeFilterValues[filter.value]) {
        option.setAttribute('selected', 'true');
      }
      dropdown.append(option);
    });

    filter.options.forEach((o) {
      var option = html.OptionElement()
        ..setAttribute('value', o.value)
        ..appendText(o.label);
      if (o.value == compareThemeFilterValues[filter.value]) {
        option.setAttribute('selected', 'true');
      }
      compare.append(option);
    });

    dropdownCol.append(dropdown);
    compareCol.append(compare);

    if (activeFilters.contains(filter.value)) {
      checkbox.setAttribute('checked', 'true');
      dropdown.removeAttribute('disabled');

      if (isCompareEnabled) {
        compare.removeAttribute('disabled');
      }
    }

    row..append(checkboxCol)..append(dropdownCol)..append(compareCol);
    return row;
  }

  void renderInteractionThemeFilters(
      List<model.InteractionFilter> filters,
      Map<String, String> themeFilterValues,
      Map<String, String> compareThemeFilterValues,
      List<String> activeFilters,
      bool isCompareEnabled) {
    analyseThemesFilterWrapper.children.clear();

    filters.forEach((f) {
      analyseThemesFilterWrapper.append(_getThemeFilterRow(f, themeFilterValues,
          compareThemeFilterValues, activeFilters, isCompareEnabled));
    });
  }

  html.DivElement _getDemogFilterRow(model.InteractionFilter filter,
      Map<String, String> themeFilterValues, List<String> activeFilters) {
    var row = html.DivElement()..classes = ['row'];
    var checkboxCol = html.DivElement()..classes = ['col-2'];
    var dropdownCol = html.DivElement()..classes = ['col-2'];

    var label = html.LabelElement()
      ..text = filter.label
      ..htmlFor = 'demog_' + filter.value;
    var checkbox = html.CheckboxInputElement()
      ..setAttribute('id', 'demog_' + filter.value)
      ..onChange.listen((e) {
        if ((e.target as html.CheckboxInputElement).checked) {
          controller.addToActiveThemeFilters(filter.value);
        } else {
          controller.removeFromActiveFilters(filter.value);
        }
      });
    checkboxCol..append(checkbox)..append(label);

    var dropdown = html.SelectElement()
      ..setAttribute('disabled', 'true')
      ..onChange.listen((e) {
        var value = (e.target as html.SelectElement).value;
        controller.chooseInteractionThemeFilter(filter.value, value);
      });

    filter.options.forEach((o) {
      var option = html.OptionElement()
        ..setAttribute('value', o.value)
        ..appendText(o.label);
      if (o.value == themeFilterValues[filter.value]) {
        option.setAttribute('selected', 'true');
      }
      dropdown.append(option);
    });
    dropdownCol.append(dropdown);

    if (activeFilters.contains(filter.value)) {
      dropdown.removeAttribute('disabled');
      checkbox.setAttribute('checked', 'true');
    }

    row..append(checkboxCol)..append(dropdownCol);
    return row;
  }

  void renderInteractionDemogFilters(List<model.InteractionFilter> filters,
      Map<String, String> themeFilterValues, List<String> activeFilters) {
    analyseDemogFilterWrapper.children.clear();

    filters.forEach((f) {
      analyseDemogFilterWrapper
          .append(_getDemogFilterRow(f, themeFilterValues, activeFilters));
    });
  }

  void renderInteractionDemogThemes(List<model.Option> themes,
      bool isCompareEnabled, String theme, String compareTheme) {
    analyseDemogCompareWrapper.children.clear();

    var row = html.DivElement()..classes = ['row'];
    var dropdownCol = html.DivElement()..classes = ['col-2'];
    var compareCol = html.DivElement()..classes = ['col-2'];

    var dropdown = html.SelectElement()
      ..onChange.listen((e) {
        var value = (e.target as html.SelectElement).value;
        controller.chooseDemogTheme(value);
      });

    themes.forEach((o) {
      var option = html.OptionElement()
        ..setAttribute('value', o.value)
        ..appendText(o.label);
      if (theme == o.value) {
        option.setAttribute('selected', 'true');
      }
      dropdown.append(option);
    });

    var compare = html.SelectElement()
      ..setAttribute('disabled', 'true')
      ..onChange.listen((e) {
        var value = (e.target as html.SelectElement).value;
        controller.chooseDemogCompareTheme(value);
      });

    themes.forEach((o) {
      var option = html.OptionElement()
        ..setAttribute('value', o.value)
        ..appendText(o.label);
      if (o.value == compareTheme) {
        option.setAttribute('selected', 'true');
      }
      compare.append(option);
    });

    if (isCompareEnabled) {
      compare.removeAttribute('disabled');
    }

    dropdownCol.append(dropdown);
    compareCol.append(compare);

    row..append(dropdownCol)..append(compareCol);

    analyseDemogCompareWrapper.append(row);
  }

  void render() {
    _updateNavbar();
    _updateContent();
  }
}
