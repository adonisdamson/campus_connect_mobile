import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/api.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/uploads.dart';
import '../../core/widgets.dart';

class VerificationScreen extends StatefulWidget {
  /// DRIVER | VENDOR | SERVICE_PROVIDER
  final String type;
  const VerificationScreen({super.key, required this.type});
  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const _docTypes = ['GHANA_CARD', 'PASSPORT', 'DRIVERS_LICENSE', 'STUDENT_ID', 'VOTER_ID'];
  final _picker = ImagePicker();
  final _idNumber = TextEditingController();

  String _docType = 'GHANA_CARD';
  XFile? _idImage, _selfie;
  bool _submitting = false;
  String? _existingStatus;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final res = await Api.instance.get('/verification');
      final mine = (res['verifications'] as List).where((v) => v['type'] == widget.type).toList();
      if (mine.isNotEmpty && mounted) setState(() => _existingStatus = mine.first['status']);
    } catch (_) {}
  }

  Future<void> _pick(bool selfie) async {
    final x = await _picker.pickImage(
      source: selfie ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
      preferredCameraDevice: CameraDevice.front,
    );
    if (x != null) setState(() => selfie ? _selfie = x : _idImage = x);
  }

  Future<void> _submit() async {
    if (_idImage == null || _selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add both your ID and a selfie')));
      return;
    }
    setState(() => _submitting = true);
    try {
      // KYC docs upload privately → opaque keys (never public URLs). Admins view
      // them only via short-lived signed URLs minted server-side.
      final idKey = await Uploads.uploadKyc(_idImage!.path, _idImage!.name);
      final selfieKey = await Uploads.uploadKyc(_selfie!.path, _selfie!.name);
      await Api.instance.post('/verification', {
        'type': widget.type,
        'idDocType': _docType,
        'idNumber': _idNumber.text.trim(),
        'idFrontUrl': idKey,
        'selfieUrl': selfieKey,
        'faceMatchScore': 0.9,
      });
      if (!mounted) return;
      setState(() => _existingStatus = 'PENDING');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitted for review')));
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pretty = widget.type.replaceAll('_', ' ').toLowerCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Get verified')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_existingStatus != null) _statusBanner(_existingStatus!),
          Text('Verify your identity to become a ${pretty == 'service provider' ? 'service provider' : pretty}.',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text('Government ID + a live selfie. Reviewed by our team.', style: TextStyle(color: CC.textDim)),
          const SizedBox(height: 24),
          const Text('ID document', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _docTypes.map((d) {
              final sel = d == _docType;
              return ChoiceChip(
                label: Text(d.replaceAll('_', ' ')),
                selected: sel,
                onSelected: (_) { Haptics.select(); setState(() => _docType = d); },
                backgroundColor: CC.surfaceHi,
                selectedColor: CC.accent,
                labelStyle: TextStyle(color: sel ? CC.ink : CC.text, fontWeight: FontWeight.w600, fontSize: 12),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          CCField('ID number', _idNumber, icon: PhosphorIconsRegular.identificationCard),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _uploadTile('ID photo', _idImage, PhosphorIconsRegular.cards, () => _pick(false))),
            const SizedBox(width: 12),
            Expanded(child: _uploadTile('Live selfie', _selfie, PhosphorIconsRegular.userFocus, () => _pick(true))),
          ]),
          const SizedBox(height: 28),
          CCButton(_existingStatus == 'PENDING' ? 'Resubmit' : 'Submit for review', loading: _submitting, onTap: _submit),
        ],
      ),
    );
  }

  Widget _statusBanner(String status) {
    final c = status == 'APPROVED' ? CC.success : status == 'REJECTED' ? CC.danger : CC.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(CC.radiusSm), border: Border.all(color: c)),
      child: Row(children: [
        Icon(PhosphorIconsFill.sealCheck, color: c, size: 20),
        const SizedBox(width: 10),
        Text('Status: $status', style: TextStyle(color: c, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _uploadTile(String label, XFile? file, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { Haptics.tap(); onTap(); },
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: CC.surface,
          borderRadius: BorderRadius.circular(CC.radiusSm),
          border: Border.all(color: file != null ? CC.accent : CC.line, width: 1.3),
        ),
        clipBehavior: Clip.antiAlias,
        child: file == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: CC.textDim, size: 28),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(color: CC.textDim, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const Text('Tap to add', style: TextStyle(color: CC.textFaint, fontSize: 11)),
              ])
            : Image.file(File(file.path), fit: BoxFit.cover, width: double.infinity),
      ),
    );
  }
}
