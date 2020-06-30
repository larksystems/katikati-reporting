import 'dart:convert';
import 'dart:io';

void main() async {
  var baseConfigFile = File('deploy/base_config.json');
  var projConfigFile = File('deploy/project_config.json');
  if (!await baseConfigFile.exists() || !await projConfigFile.exists()) {
    throw ArgumentError('Config files not present');
  }

  var baseConfigRaw = await baseConfigFile.readAsString();
  Map<String, dynamic> baseConfig = jsonDecode(baseConfigRaw);
  var projConfigRaw = await projConfigFile.readAsString();
  Map<String, dynamic> projConfig = jsonDecode(projConfigRaw);

  var buildStatus = projConfig.map((proj, projConfig) {
    print('---------- ${proj} ----------');
    print('${proj}: Building project ...');
    var newConfig = {...baseConfig, ...projConfig};
    var newFile = File('web/assets/firebase-constants.json');
    newFile.writeAsStringSync(jsonEncode(newConfig));
    print('${proj}: Generated config');

    print('${proj}: Running webdev build..');
    var buildRes = Process.runSync(
        'webdev', ['build', '--output', 'build/${proj}'],
        runInShell: true);
    if (buildRes.stderr != '') {
      print(buildRes.stderr);
      print('${proj}: Build FAILED');
      throw StateError('Error in ${proj}, build stopped');
    } else {
      print(buildRes.stdout);
      print('${proj}: Build SUCCESSFUL');
      return MapEntry(proj, 'success');
    }
  });

  print('''---------- Build report ----------\n${buildStatus}\n\n''');
}
