import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final inputPath = 'assets/images/Logo Endog Racing Hijau.png';
  final outputPath = 'assets/images/Icon_Logo_Square.png';

  print('Reading image...');
  final imageBytes = File(inputPath).readAsBytesSync();
  var original = img.decodeImage(imageBytes);

  if (original == null) {
    print('Failed to decode image.');
    return;
  }
  
  // Resize to exactly 1000 width, keeping aspect ratio
  original = img.copyResize(original, width: 1000);
  print('Resized original to: ${original.width}x${original.height}');

  // Create a much larger square canvas so the logo is small in the middle
  // Canvas is 2000x2000
  final int paddedSize = 2000;

  // Create a transparent square canvas
  final padded = img.Image(width: paddedSize, height: paddedSize, numChannels: 4);
  img.fill(padded, color: img.ColorRgba8(0, 0, 0, 0));

  // Center the image
  final int offsetX = (paddedSize - original.width) ~/ 2;
  final int offsetY = (paddedSize - original.height) ~/ 2;

  img.compositeImage(padded, original, dstX: offsetX, dstY: offsetY);

  File(outputPath).writeAsBytesSync(img.encodePng(padded));
  print('Done squaring icon!');
}
