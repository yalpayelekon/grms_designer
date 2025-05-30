import 'package:file_picker/file_picker.dart';

class FileDialogHelper {
  static Future<String?> pickJsonFileToOpen() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Select HelvarNet workgroups file to import',
    );

    if (result != null && result.files.single.path != null) {
      return result.files.single.path;
    }
    return null;
  }

  static Future<String?> pickJsonFileToSave(String fileName) async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save HelvarNet configuration',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    return outputFile;
  }

  static Future<String?> pickTextFileToSave(String fileName) async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Logs',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    return outputFile;
  }

  static Future<String?> pickFileToOpen({
    List<String> allowedExtensions = const ['json'],
    String dialogTitle = 'Select file to import',
    FileType type = FileType.custom,
  }) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: type == FileType.custom ? allowedExtensions : null,
      dialogTitle: dialogTitle,
    );

    if (result != null && result.files.single.path != null) {
      return result.files.single.path;
    }
    return null;
  }
}
