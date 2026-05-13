import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';

part 'chat_provider.g.dart';

class ChatMessage {
  final int? id;
  final bool isUser;
  final String text;

  const ChatMessage({this.id, required this.isUser, required this.text});

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] as int?,
    isUser: j['role'] == 'user',
    text: j['content'] as String? ?? '',
  );
}

@riverpod
class ChatNotifier extends _$ChatNotifier {
  String? _threadId;

  @override
  Future<List<ChatMessage>> build() async {
    return _loadHistory();
  }

  Future<List<ChatMessage>> _loadHistory() async {
    try {
      final resp = await apiDio.get(
        '/api/v1/chat/history',
        queryParameters: {'limit': 50},
      );
      final data = resp.data as Map<String, dynamic>;
      _threadId = data['thread_id'] as String?;
      final msgs = data['messages'] as List? ?? [];
      return msgs
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> send(String text, String mode) async {
    final userMsg = ChatMessage(isUser: true, text: text);
    state = AsyncData([...?state.valueOrNull, userMsg]);

    try {
      final resp = await apiDio.post('/api/v1/chat/message', data: {
        'message': text,
        if (_threadId != null) 'thread_id': _threadId,
      });
      final data = resp.data as Map<String, dynamic>;
      _threadId = data['thread_id'] as String?;
      final reply = data['reply'] as String? ?? '';
      final aiMsg = ChatMessage(isUser: false, text: reply);
      state = AsyncData([...?state.valueOrNull, aiMsg]);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
