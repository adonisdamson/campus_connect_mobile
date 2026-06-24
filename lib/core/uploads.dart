import 'api.dart';

/// Image upload. Posts the file to the backend's authenticated `/uploads`
/// endpoint, which stores it on disk and returns a real, viewable URL. No cloud
/// bucket required — "everything local" — so KYC docs and photos are genuine.
class Uploads {
  /// Uploads [filePath] and returns the public URL the backend serves it at.
  /// Throws [ApiException] on failure so callers surface a real error instead
  /// of silently submitting a broken reference.
  static Future<String> uploadImage(String filePath, String fileName) async {
    final res = await Api.instance.uploadFile('/uploads', filePath, fileName: fileName);
    final url = res['url'] as String?;
    if (url == null || url.isEmpty) {
      throw ApiException('Upload failed — please try again');
    }
    return url;
  }
}
