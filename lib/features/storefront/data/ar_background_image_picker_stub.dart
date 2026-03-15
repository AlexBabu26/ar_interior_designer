import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Picks an image file (non-web). Returns file name and bytes, or null if cancelled.
Future<({String name, List<int> bytes})?> pickArBackgroundImage() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
    allowMultiple: false,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.single;
  List<int> bytes;
  if (file.bytes != null && file.bytes!.isNotEmpty) {
    bytes = file.bytes!;
  } else if (file.path != null) {
    final f = File(file.path!);
    if (!await f.exists()) return null;
    bytes = await f.readAsBytes();
  } else {
    return null;
  }
  return (name: file.name, bytes: bytes);
}
