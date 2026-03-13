import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> savePdfBytes(Uint8List bytes, String filename) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  web.document.body!.removeChild(anchor);
  web.URL.revokeObjectURL(url);
}

/// Try Web Share API with file (works on mobile browsers).
/// Returns true if share was successful, false if not supported.
Future<bool> sharePdfBytes(Uint8List bytes, String filename) async {
  try {
    final file = web.File(
      [bytes.toJS].toJS,
      filename,
      web.FilePropertyBag(type: 'application/pdf'),
    );
    final shareData = web.ShareData(files: [file].toJS);
    if (web.window.navigator.canShare(shareData)) {
      await web.window.navigator.share(shareData).toDart;
      return true;
    }
  } catch (_) {}
  // Fallback: just download the file
  await savePdfBytes(bytes, filename);
  return false;
}
