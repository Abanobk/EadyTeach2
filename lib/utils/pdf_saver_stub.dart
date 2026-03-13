import 'dart:typed_data';

Future<void> savePdfBytes(Uint8List bytes, String filename) async {
  throw UnsupportedError('savePdfBytes not supported on this platform');
}

Future<bool> sharePdfBytes(Uint8List bytes, String filename) async {
  return false;
}
