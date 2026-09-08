import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final inputPath = 'assets/images/Logo Endog Racing Hijau.png';
  final outputPath = 'assets/images/Splash_Logo_Endog_Racing_Hijau.png';

  print('Reading image...');
  final imageBytes = File(inputPath).readAsBytesSync();
  var original = img.decodeImage(imageBytes);

  if (original == null) {
    print('Failed to decode image.');
    return;
  }
  
  // Resize if it's too huge to avoid memory/cache issues on Android
  if (original.width > 1000) {
    original = img.copyResize(original, width: 1000);
    print('Resized original to: ${original.width}x${original.height}');
  }

  // Calculate new size (add 100% padding to be super safe)
  final double paddingFactor = 2.0; 
  final int targetSize = (original.width > original.height ? original.width * paddingFactor : original.height * paddingFactor).round();

  print('Target padded size: ${targetSize}x${targetSize}');

  // Create a transparent background image explicitly
  final padded = img.Image(width: targetSize, height: targetSize, numChannels: 4);
  // Fill with transparent
  img.fill(padded, color: img.ColorRgba8(0, 0, 0, 0));

  // Calculate position to center the original image
  final int offsetX = (targetSize - original.width) ~/ 2;
  final int offsetY = (targetSize - original.height) ~/ 2;

  print('Compositing image at offset: $offsetX, $offsetY');
  img.compositeImage(padded, original, dstX: offsetX, dstY: offsetY);

  print('Saving padded image...');
  File(outputPath).writeAsBytesSync(img.encodePng(padded));
  
  print('Done!');
}
