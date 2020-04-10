import 'dart:html' as html;
import 'model.dart' as model;
import 'utils.dart' as util;
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
html.DivElement get analyseThemesContent =>
    html.querySelector('#analyse-themes-content');
html.DivElement get analyseDemographicsContent =>
    html.querySelector('#analyse-demographics-content');

class View {
  Controller controller;

  View() {
    _listenToNavbarChanges();
    _listenToMessagesSort();

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

  void chooseInteractionThemes() {}

  void render() {
    _updateNavbar();
    _updateContent();
  }
}
