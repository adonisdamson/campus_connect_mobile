import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/api.dart';
import '../../core/skeletons.dart';
import '../../core/socket.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    SocketService.instance.on('notification:new', (d) {
      if (mounted) setState(() => _items.insert(0, {...d, 'isRead': false, 'createdAt': DateTime.now().toIso8601String()}));
    });
  }

  @override
  void dispose() {
    SocketService.instance.off('notification:new');
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await Api.instance.get('/notifications');
      _items = res['notifications'] as List? ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _readAll() async {
    await Api.instance.patch('/notifications/read-all').catchError((_) => <String, dynamic>{});
    _load();
  }

  IconData _iconFor(String type) => switch (type) {
        'RIDE' => PhosphorIconsFill.car,
        'DELIVERY' => PhosphorIconsFill.package,
        'PAYMENT' => PhosphorIconsFill.wallet,
        'MARKETPLACE' => PhosphorIconsFill.storefront,
        'SERVICE' => PhosphorIconsFill.calendarCheck,
        'PROMO' => PhosphorIconsFill.tag,
        'CHAT' => PhosphorIconsFill.chatCircle,
        _ => PhosphorIconsFill.bell,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), actions: [
        if (_items.isNotEmpty) TextButton(onPressed: _readAll, child: const Text('Mark all read', style: TextStyle(color: CC.lime))),
      ]),
      body: _loading
          ? Skeletons.tiles()
          : _items.isEmpty
              ? const CCEmpty(icon: PhosphorIconsRegular.bell, title: 'All caught up', subtitle: 'Ride, delivery and payment updates land here.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(color: CC.line, height: 1),
                    itemBuilder: (_, i) {
                      final n = _items[i];
                      final read = n['isRead'] == true;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: read ? CC.surfaceHi : CC.accent.withValues(alpha: 0.18),
                          child: Icon(_iconFor('${n['type']}'), color: read ? CC.textDim : CC.accent, size: 18),
                        ),
                        title: Text('${n['title'] ?? ''}', style: TextStyle(fontWeight: read ? FontWeight.w500 : FontWeight.w700)),
                        subtitle: Text('${n['body'] ?? ''}', style: const TextStyle(color: CC.textDim)),
                        trailing: read ? null : const CircleAvatar(radius: 4, backgroundColor: CC.lime),
                      );
                    },
                  ),
                ),
    );
  }
}
