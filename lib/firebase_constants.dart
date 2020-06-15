library firebase.constants;

import 'dart:convert' as convert;
import 'dart:html' as html;

void init(String _constantsFilePath) async {
  if (_constants != null) return;

  var constantsJson = await html.HttpRequest.getString(_constantsFilePath);
  _constants = (convert.json.decode(constantsJson) as Map).map<String, String>(
      (key, value) => MapEntry(key.toString(), value.toString()));
}

Map<String, String> _constants;

String get apiKey => _constants['apiKey'];
String get authDomain => _constants['authDomain'];
String get databaseURL => _constants['databaseURL'];
String get projectId => _constants['projectId'];
String get storageBucket => _constants['storageBucket'];
String get messagingSenderId => _constants['messagingSenderId'];
String get appId => _constants['appId'];
String get measurementId => _constants['measurementId'];
List<String> get allowedEmailDomains =>
    _constants['allowedEmailDomains'].split('|');
String get metadataPath => _constants['metadataPath'];
