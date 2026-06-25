import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/campus.dart';
import '../../core/haptics.dart';
import '../../core/skeletons.dart';
import '../../core/theme.dart';
import '../../models.dart';

/// Pick your university. Live (pilot) campuses are selectable; the rest show
/// "Coming soon" — Campus Connect serves all Ghanaian universities.
Future<University?> pickCampus(BuildContext context) {
  return showModalBottomSheet<University>(
    context: context,
    isScrollControlled: true,
    backgroundColor: CC.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _CampusPicker(),
  );
}

class _CampusPicker extends StatefulWidget {
  const _CampusPicker();
  @override
  State<_CampusPicker> createState() => _CampusPickerState();
}

class _CampusPickerState extends State<_CampusPicker> {
  List<University> _unis = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    CampusService.load().then((u) {
      if (mounted) setState(() { _unis = u; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: CC.line, borderRadius: BorderRadius.circular(4))),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(alignment: Alignment.centerLeft, child: Text('Choose your university', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19))),
        ),
        Expanded(
          child: _loading
              ? Skeletons.list()
              : ListView.separated(
                  itemCount: _unis.length,
                  separatorBuilder: (_, __) => const Divider(color: CC.line, height: 1),
                  itemBuilder: (_, i) {
                    final u = _unis[i];
                    return ListTile(
                      enabled: u.isActive,
                      leading: Icon(PhosphorIconsFill.graduationCap, color: u.isActive ? CC.accent : CC.textFaint),
                      title: Text(u.shortName, style: TextStyle(fontWeight: FontWeight.w700, color: u.isActive ? CC.text : CC.textFaint)),
                      subtitle: Text('${u.name} • ${u.city}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CC.textDim, fontSize: 12)),
                      trailing: u.isActive
                          ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: CC.success.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)), child: const Text('Live', style: TextStyle(color: CC.success, fontSize: 11, fontWeight: FontWeight.w800)))
                          : const Text('Soon', style: TextStyle(color: CC.textFaint, fontSize: 11, fontWeight: FontWeight.w700)),
                      onTap: u.isActive ? () { Haptics.tap(); Navigator.pop(context, u); } : null,
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
