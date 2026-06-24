import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/api.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Show a star-rating sheet and POST /reviews. Returns true if submitted.
Future<bool> showRateSheet(
  BuildContext context, {
  required String subjectType, // DRIVER | ORDER | VENDOR | SERVICE ...
  required String subjectId,
  String? targetUserId,
  String title = 'Rate your experience',
}) async {
  final res = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: CC.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _RateSheet(subjectType: subjectType, subjectId: subjectId, targetUserId: targetUserId, title: title),
  );
  return res ?? false;
}

class _RateSheet extends StatefulWidget {
  final String subjectType, subjectId, title;
  final String? targetUserId;
  const _RateSheet({required this.subjectType, required this.subjectId, required this.title, this.targetUserId});
  @override
  State<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<_RateSheet> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await Api.instance.post('/reviews', {
        'subjectType': widget.subjectType,
        'subjectId': widget.subjectId,
        if (widget.targetUserId != null) 'targetUserId': widget.targetUserId,
        'rating': _rating,
        'comment': _comment.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: CC.line, borderRadius: BorderRadius.circular(4)))),
        const SizedBox(height: 18),
        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
          final on = i < _rating;
          return IconButton(
            iconSize: 38,
            onPressed: () => setState(() => _rating = i + 1),
            icon: Icon(on ? PhosphorIconsFill.star : PhosphorIconsRegular.star, color: on ? CC.warning : CC.textFaint),
          );
        })),
        const SizedBox(height: 12),
        CCField('Add a comment (optional)', _comment, icon: PhosphorIconsRegular.chatText),
        const SizedBox(height: 20),
        CCButton('Submit rating', loading: _submitting, onTap: _submit),
        const SizedBox(height: 8),
        Center(child: TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Skip', style: TextStyle(color: CC.textDim)))),
      ]),
    );
  }
}
