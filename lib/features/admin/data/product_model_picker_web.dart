import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Picks a .glb/.gltf file on web using the browser file input (avoids file_picker web init bug).
Future<({String name, List<int> bytes})?> pickProductModelFile() async {
  final input = html.FileUploadInputElement()
    ..accept = '.glb,.gltf'
    ..multiple = false
    ..style.position = 'absolute'
    ..style.left = '-9999px'
    ..style.width = '1px'
    ..style.height = '1px'
    ..style.opacity = '0';

  final done = Completer<({String name, List<int> bytes})?>();
  void listener(html.Event e) {
    input.removeEventListener('change', listener);
    final files = input.files;
    if (files == null || files.length == 0) {
      input.remove();
      done.complete(null);
      return;
    }
    final file = files[0];
    input.remove();

    void completeWithBytes(List<int> bytes) {
      if (bytes.isEmpty) {
        done.complete(null);
        return;
      }
      done.complete((name: file.name, bytes: bytes));
    }

    void tryReadAsDataUrl() {
      final reader2 = html.FileReader();
      reader2.onLoadEnd.listen((_) {
        final result = reader2.result;
        if (result is String && result.startsWith('data:')) {
          final base64 = result.contains('base64,')
              ? result.split('base64,').last.trim()
              : result;
          try {
            completeWithBytes(base64Decode(base64));
          } catch (_) {
            done.complete(null);
          }
        } else {
          done.complete(null);
        }
      });
      reader2.onError.listen((_) => done.complete(null));
      reader2.readAsDataUrl(file);
    }

    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result == null) {
        tryReadAsDataUrl();
        return;
      }
      if (result is ByteBuffer) {
        completeWithBytes(result.asUint8List().toList());
      } else {
        tryReadAsDataUrl();
      }
    });
    reader.onError.listen((_) => tryReadAsDataUrl());
    reader.readAsArrayBuffer(file);
  }

  input.addEventListener('change', listener);
  final target = html.document.body ?? html.document.documentElement;
  target?.append(input);
  // Click synchronously so Chrome treats it as a user gesture (no await before click)
  input.click();
  return done.future;
}
