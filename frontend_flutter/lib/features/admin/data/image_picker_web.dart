import 'dart:html' as html;
import 'dart:typed_data';

import 'picked_image.dart';

Future<PickedImage?> pickProductImage() async {
  final input = html.FileUploadInputElement()
    ..accept =
        'image/jpeg,image/png,image/webp,image/gif,image/bmp,image/svg+xml,image/heic,image/heif'
    ..multiple = false;

  input.click();

  await input.onChange.first;

  final file = input.files?.first;
  if (file == null) return null;

  final reader = html.FileReader();
  reader.readAsArrayBuffer(file);
  await reader.onLoad.first;

  final result = reader.result;
  if (result == null) return null;

  final bytes = result is ByteBuffer
      ? Uint8List.view(result)
      : Uint8List.fromList(result as List<int>);

  return PickedImage(
    name: file.name,
    bytes: bytes,
    mimeType: file.type.isNotEmpty ? file.type : mimeTypeFromFileName(file.name),
  );
}
