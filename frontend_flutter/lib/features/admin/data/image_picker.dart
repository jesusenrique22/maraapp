import 'picked_image.dart';
import 'image_picker_io.dart' if (dart.library.html) 'image_picker_web.dart' as impl;

export 'picked_image.dart';

Future<PickedImage?> pickProductImage() => impl.pickProductImage();
