import 'dart:io';

void main() {
  // Folder to process (usually your Flutter lib folder)
  var projectDir = Directory('lib');

  // List of files or folders to exclude (relative paths)
  var excludedPaths = [
    'lib/special_file.dart', // single file
    'lib/generated', // folder (all files inside will be skipped)
  ];

  // Recursively get all .dart files
  var files = projectDir.listSync(recursive: true).where((f) {
    if (f is File && f.path.endsWith('.dart')) {
      // Skip excluded files and folders
      for (var exclude in excludedPaths) {
        if (f.path.contains(exclude)) return false;
      }
      return true;
    }
    return false;
  });

  // Process each file
  for (var file in files) {
    var path = file.path;
    var content = File(path).readAsStringSync();

    // Remove single-line comments
    content = content.replaceAll(RegExp(r'//.*'), '');

    // Remove multi-line comments
    content = content.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');

    // Save changes
    File(path).writeAsStringSync(content);

    print('Comments removed: $path');
  }

  print('✅ Done! All comments removed except excluded files/folders.');
}
