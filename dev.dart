import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) async {
  if (arguments == null) {
    throw ArgumentError('dart dev.dart <proj-name-from-project_config.json>');
  }

  var baseConfigFile = File('config/base_config.json');
  var projConfigFile = File('config/project_config.json');
  if (!await baseConfigFile.exists() || !await projConfigFile.exists()) {
    throw ArgumentError('Config files not present');
  }

  var baseConfigRaw = await baseConfigFile.readAsString();
  Map<String, dynamic> baseConfig = jsonDecode(baseConfigRaw);
  var projConfigRaw = await projConfigFile.readAsString();
  Map<String, dynamic> projConfig = jsonDecode(projConfigRaw);

  var projName = arguments[0];

  if (projName == null || projConfig[projName] == null) {
    throw StateError('No such project found in project_config.json');
  }

  var newConfig = {...baseConfig, ...projConfig[projName]};
  var newFile = File('web/assets/firebase-constants.json');
  newFile.writeAsStringSync(jsonEncode(newConfig));
}
