library firebase.constants;

import 'dart:convert' as convert;
import 'dart:html' as html;

Map<String, dynamic> _constants;

void init(String _constantsFilePath) async {
  if (_constants != null) return;

  var constantsJson = await html.HttpRequest.getString(_constantsFilePath);
  _constants = convert.json
      .decode(constantsJson)
      .map<String, dynamic>((key, value) => MapEntry(key.toString(), value));
  // todo: show error if any of the required keys are missing
}

String get apiKey => _constants['apiKey'];
String get authDomain => _constants['authDomain'];
String get databaseURL => _constants['databaseURL'];
String get projectId => _constants['projectId'];
String get storageBucket => _constants['storageBucket'];
String get messagingSenderId => _constants['messagingSenderId'];
String get appId => _constants['appId'];
String get measurementId => _constants['measurementId'];
List<String> get allowedEmailDomains =>
    (_constants['allowedEmailDomains'] as List)
        .map((v) => v.toString())
        .toList();
String get metadataPath => _constants['metadataPath'];

String get mapboxKey => _constants['mapboxKey'];
String get mapboxStyleURL => _constants['mapboxStyleURL'];
