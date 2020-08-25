import 'dart:html' as html;

var urlRaw = html.querySelector('#url-raw');
var urlPrettified = html.querySelector('#url-prettified');

void main() {
  urlRaw.onInput.listen((event) {
    var value = (event.currentTarget as html.TextAreaElement).value;
    var uri = Uri.parse(value);
    var queryParams = uri.queryParametersAll;

    urlPrettified.innerText = queryParams.toString();
  });
}
