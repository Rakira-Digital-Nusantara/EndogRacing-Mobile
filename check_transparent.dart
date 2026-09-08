import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final b = File('assets/images/Logo Endog Racing Hijau.png').readAsBytesSync();
  var o = img.decodeImage(b)!;
  final p = o.getPixel(0, 0);
  print('Top-left pixel: R=${p.r}, G=${p.g}, B=${p.b}, A=${p.a}');
}
