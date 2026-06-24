import 'api.dart';
import 'config.dart';
import '../models.dart';

/// Multi-campus support. Loads the universities Campus Connect serves and
/// applies the selected campus centre as the app's map fallback.
class CampusService {
  static List<University> all = [];
  static University? selected;

  static Future<List<University>> load() async {
    if (all.isNotEmpty) return all;
    try {
      final res = await Api.instance.get('/universities');
      all = (res['universities'] as List).map((e) => University.fromJson(e)).toList();
    } catch (_) {}
    return all;
  }

  static void apply(University u) {
    selected = u;
    AppConfig.campusLat = u.lat;
    AppConfig.campusLng = u.lng;
  }

  /// Centre the map on the signed-in user's campus (called on bootstrap).
  static Future<void> applyForUser(String? universityId) async {
    if (universityId == null) return;
    final list = await load();
    final match = list.where((u) => u.id == universityId);
    if (match.isNotEmpty) apply(match.first);
  }
}
