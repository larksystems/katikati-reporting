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

  projName = args[0];
  if (projName == null || projConfig[projName] == null) {
    throw StateError(
        'No such ${projName} project found in project_config.json');
  }

  var newConfig = {...baseConfig, ...projConfig[projName]};
  var newFile = File('web/assets/constants.json');
  print('''Finished writing config for project ${projName}''');
  newFile.writeAsStringSync(jsonEncode(newConfig));

  print('');
  print(
      'When using webdev serve, open http://localhost:8080/ in your browser.');
  print('      .. 127.0.0.1 does not work for this app');
  print('');
}
