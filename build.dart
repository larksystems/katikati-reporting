import 'dart:convert';
import 'dart:io';

Future<File> fetchConfigFile(String path, String type) async {
  var file = File(path);
  if (!await file.exists()) {
    throw ArgumentError('${type} config file does not exist at: ${path}');
  }

  return file;
}

void main() async {
  var baseConfigFile = await fetchConfigFile('config/base_config.json', 'base');
  var baseConfigRaw = await baseConfigFile.readAsString();
  Map<String, dynamic> baseConfig = jsonDecode(baseConfigRaw);

  var projConfigFile =
      await fetchConfigFile('config/project_config.json', 'project');
  var projConfigRaw = await projConfigFile.readAsString();
  Map<String, dynamic> projConfig = jsonDecode(projConfigRaw);

  var buildStatus = projConfig.map((proj, projConfig) {
    print('---------- ${proj} ----------');
    print('${proj}: Building project ...');
    var newConfig = {...baseConfig, ...projConfig};
    var newFile = File('web/assets/constants.json');
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

  var linksList = projConfig.keys.map((key) {
    return '<li><a href="/${key}/web">${key}</a></li>';
  }).join('');
  var landingTemplate = '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>KatiKati-Reporting</title>
    </head>
    <body>
      <ul>
        ${linksList}
      </ul>
    </body>
    </html>
  ''';

  await File('build/index.html').writeAsString(landingTemplate);
  print('DONE');
}
