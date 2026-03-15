import 'package:file_picker/file_picker.dart';

/// Picks a .glb/.gltf file (uses file_picker on mobile/desktop).
Future<({String name, List<int> bytes})?> pickProductModelFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['glb', 'gltf'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.single;
  final bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) return null;
  return (name: file.name, bytes: bytes);
}
