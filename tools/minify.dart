import 'dart:io';

final projectRoot = Directory.current;
final output = File('minified_project.txt');

void main() async {
  final buffer = StringBuffer();

  await for (var entity in projectRoot.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.contains('minify.dart')) {
      final relativePath = entity.path.replaceFirst(projectRoot.path, '');
      final lines = await entity.readAsLines();

      buffer.writeln('// File: $relativePath');

      for (var line in lines) {
        final trimmed = line.trim();

        // Remove single-line and inline comments
        if (trimmed.startsWith('//')) continue;
        if (trimmed.contains('//')) {
          final index = trimmed.indexOf('//');
          buffer.write(trimmed.substring(0, index));
          buffer.write(' ');
          continue;
        }

        // Remove empty lines
        if (trimmed.isEmpty) continue;

        buffer.write('$trimmed ');
      }

      buffer.writeln('\n');
    }
  }

  await output.writeAsString(buffer.toString());
  print('Minified content written to ${output.path}');
}
