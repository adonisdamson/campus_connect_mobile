import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/api.dart';
import '../../core/skeletons.dart';
import '../../core/socket.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../auth/auth_provider.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List _convos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Api.instance.get('/chat');
      _convos = res['conversations'] as List;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _title(Map convo, String myId) {
    final others = (convo['participants'] as List? ?? []).where((p) => p['userId'] != myId).toList();
    if (others.isEmpty) return 'Conversation';
    return others.first['user']?['fullName'] ?? 'Campus user';
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthProvider>().user?.id ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _loading
          ? Skeletons.tiles()
          : _convos.isEmpty
              ? const CCEmpty(icon: PhosphorIconsRegular.chatCircle, title: 'No messages yet', subtitle: 'Chats with drivers, sellers and vendors show up here.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _convos.length,
                    separatorBuilder: (_, __) => const Divider(color: CC.line, height: 1),
                    itemBuilder: (_, i) {
                      final c = _convos[i];
                      final last = (c['messages'] as List?)?.isNotEmpty == true ? c['messages'][0]['body'] : 'Say hi 👋';
                      final title = _title(c, myId);
                      return ListTile(
                        leading: CCAvatar(title.isNotEmpty ? title[0].toUpperCase() : 'C'),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('$last', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CC.textDim)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatThreadScreen(c['id'], title))),
                      );
                    },
                  ),
                ),
    );
  }
}

class ChatThreadScreen extends StatefulWidget {
  final String conversationId, title;
  const ChatThreadScreen(this.conversationId, this.title, {super.key});
  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final List _messages = [];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    SocketService.instance.on('chat:new-message', (d) {
      if (d['conversationId'] == widget.conversationId && mounted) {
        setState(() => _messages.add(d['message']));
        _toBottom();
      }
    });
  }

  @override
  void dispose() {
    SocketService.instance.off('chat:new-message');
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await Api.instance.get('/chat/${widget.conversationId}/messages');
      _messages.addAll(res['messages'] as List);
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      _toBottom();
    }
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty) return;
    _input.clear();
    try {
      final res = await Api.instance.post('/chat/${widget.conversationId}/messages', {'body': body});
      setState(() => _messages.add(res['message']));
      _toBottom();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthProvider>().user?.id ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      final mine = m['senderId'] == myId;
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                          decoration: BoxDecoration(
                            color: mine ? CC.accent : CC.surfaceHi,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(mine ? 16 : 4),
                              bottomRight: Radius.circular(mine ? 4 : 16),
                            ),
                          ),
                          child: Text('${m['body'] ?? ''}', style: TextStyle(color: mine ? CC.ink : CC.text)),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(child: CCField('Message…', _input)),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: CC.accent,
                    child: IconButton(icon: const Icon(PhosphorIconsFill.paperPlaneRight, color: CC.ink, size: 20), onPressed: _send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
