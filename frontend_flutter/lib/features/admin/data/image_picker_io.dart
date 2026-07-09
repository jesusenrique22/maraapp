import 'package:file_picker/file_picker.dart';

import 'picked_image.dart';

Future<PickedImage?> pickProductImage() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
    withData: true,
  );

  if (result == null || result.files.isEmpty) return null;

  final file = result.files.first;
  if (file.bytes == null) return null;

  return PickedImage(
    name: file.name,
    bytes: file.bytes!,
    mimeType: mimeTypeFromFileName(file.name),
  );
}
