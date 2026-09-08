import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final b = File('assets/images/Icon_Logo_Square.png').readAsBytesSync();
  var o = img.decodeImage(b)!;
  print('Square Icon Dimensions: ${o.width}x${o.height}');
}
