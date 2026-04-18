import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final apiKey = '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';
  final url = Uri.parse('https://ai.api.nvidia.com/v1/genai/stabilityai/stable-diffusion-xl');

  final b64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
  final dataUri = 'data:image/png;base64,$b64';

  final body = {
    'text_prompts': [{'text': 'A dog', 'weight': 1}],
    'init_image': b64,
    'cfg_scale': 7.5,
    'steps': 30,
    'seed': 0,
    'image_strength': 0.5,
  };

  print('Sending SDXL request...');
  final req = await HttpClient().postUrl(url);
  req.headers.add('Content-Type', 'application/json');
  req.headers.add('Accept', 'application/json');
  req.headers.add('Authorization', 'Bearer $apiKey');
  req.write(jsonEncode(body));

  final res = await req.close();
  print('Status: ${res.statusCode}');
  
  final resBody = await res.transform(utf8.decoder).join();
  print('Body: $resBody');
}
