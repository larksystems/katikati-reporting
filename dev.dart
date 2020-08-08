import 'dart:convert';
import 'dart:io';

Future<File> fetchConfigFile(String path, String type) async {
  var file = File(path);
  if (!await file.exists()) {
    throw ArgumentError('${type} config file does not exist at: ${path}');
  }

  return file;
}

void main(List<String> args) async {
  var baseConfigFile = await fetchConfigFile('config/base_config.json', 'base');
  var baseConfigRaw = await baseConfigFile.readAsString();
  Map<String, dynamic> baseConfig = jsonDecode(baseConfigRaw);

  var projConfigFile =
      await fetchConfigFile('config/project_config.json', 'project');
  var projConfigRaw = await projConfigFile.readAsString();
  Map<String, dynamic> projConfig = jsonDecode(projConfigRaw);

  var projName;

  if (args == null) {
    projName = projConfig.keys.first;
    print(
        '''No project specified. Usage: dart dev.dart <proj-name-from-project_config.json>\nConsidering the first project under config/project_config ** ${projName} **''');
  } else {
    projName = args[0];
    if (projName == null || projConfig[projName] == null) {
      throw StateError(
          'No such ${projName} project found in project_config.json');
    }
  }

  var newConfig = {...baseConfig, ...projConfig[projName]};
  var newFile = File('web/assets/constants.json');
  print('''Finished writing config for project ${projName}''');
  newFile.writeAsStringSync(jsonEncode(newConfig));
}
