import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// Custom file wrapper to handle both web and mobile files
class CustomPlatformFile {
  final String name;
  final String? path;
  final Uint8List? bytes;
  final bool isWeb;
  
  CustomPlatformFile({
    required this.name,
    this.path,
    this.bytes,
    required this.isWeb,
  });
  
  // Create from FilePicker result
  static CustomPlatformFile? fromPickerFile(dynamic pickerFile) {
    if (kIsWeb) {
      if (pickerFile.bytes != null) {
        return CustomPlatformFile(
          name: pickerFile.name,
          bytes: pickerFile.bytes,
          isWeb: true,
        );
      }
    } else {
      if (pickerFile.path != null) {
        return CustomPlatformFile(
          name: pickerFile.name,
          path: pickerFile.path,
          isWeb: false,
        );
      }
    }
    return null;
  }
  
  // Get file bytes
  Future<Uint8List?> getBytes() async {
    if (isWeb) {
      return bytes;
    } else if (path != null) {
      try {
        final file = File(path!);
        return await file.readAsBytes();
      } catch (e) {
        print("Error reading file bytes: $e");
        return null;
      }
    }
    return null;
  }
}