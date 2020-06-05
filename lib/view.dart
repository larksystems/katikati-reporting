import 'dart:html' as html;

const LOADING_MODAL_ID = 'loading-modal';

html.DivElement get loadingModal => html.querySelector('#${LOADING_MODAL_ID}');

class View {
  void showLoadingIndicator() {
    loadingModal.removeAttribute('hidden');
  }

  void hideLoadingIndicator() {
    loadingModal.setAttribute('hidden', 'true');
  }
}
