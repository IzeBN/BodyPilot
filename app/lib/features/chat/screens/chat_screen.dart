import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/chat_provider.dart';

enum _ChatMode { nutrition, training }

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  _ChatMode _mode = _ChatMode.nutrition;
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    final modeStr = _mode == _ChatMode.nutrition ? 'nutrition' : 'training';
    await ref.read(chatNotifierProvider.notifier).send(text, modeStr);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final chatAsync = ref.watch(chatNotifierProvider);
    final isLoading = chatAsync.isLoading;
    final messages = chatAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(l),
            _buildModePills(l),
            Expanded(child: _buildMessages(context, messages, isLoading)),
            _buildInput(l),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AppL10n l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(l.chatTitle, style: AppText.appBarTitle()),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(AppRadius.appBarAction),
            ),
            child: const Center(
              child: Text('📜', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModePills(AppL10n l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: _ModePill(
              icon: '🥗',
              label: l.chatModeNutrition,
              desc: l.chatModeNutritionDesc,
              active: _mode == _ChatMode.nutrition,
              activeColor: AppColors.brandBlueDeep,
              activeBg: AppColors.brandBlueSoft,
              activeBorder: AppColors.brandBlue,
              onTap: () => setState(() => _mode = _ChatMode.nutrition),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModePill(
              icon: '🏋️',
              label: l.chatModeTraining,
              desc: l.chatModeTrainingDesc,
              active: _mode == _ChatMode.training,
              activeColor: const Color(0xFFC2410C),
              activeBg: const Color(0xFFFFF7ED),
              activeBorder: AppColors.coralStart,
              onTap: () => setState(() => _mode = _ChatMode.training),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(BuildContext context, List<ChatMessage> messages, bool isLoading) {
    return ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: messages.length + (isLoading ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == messages.length) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: _TypingIndicator(),
          );
        }
        final msg = messages[i];
        return Align(
          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: msg.isUser ? AppColors.brandBlue : AppColors.surfaceTint,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadius.chatBubble),
                topRight: const Radius.circular(AppRadius.chatBubble),
                bottomLeft: Radius.circular(msg.isUser ? AppRadius.chatBubble : 4),
                bottomRight: Radius.circular(msg.isUser ? 4 : AppRadius.chatBubble),
              ),
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                fontSize: 14,
                color: msg.isUser ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput(AppL10n l) {
    final hint = _mode == _ChatMode.nutrition
        ? l.chatPlaceholderNutrition
        : l.chatPlaceholderTraining;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: TextField(
                controller: _textCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Mic button matching design SVG
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.brandBlue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(16, 16),
                  painter: _MicPainter(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  final String icon;
  final String label;
  final String desc;
  final bool active;
  final Color activeColor;
  final Color activeBg;
  final Color activeBorder;
  final VoidCallback onTap;

  const _ModePill({
    required this.icon,
    required this.label,
    required this.desc,
    required this.active,
    required this.activeColor,
    required this.activeBg,
    required this.activeBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: active ? activeBg : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? activeBorder : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? activeColor : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(desc, style: AppText.meta(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.chatBubble),
          topRight: Radius.circular(AppRadius.chatBubble),
          bottomRight: Radius.circular(AppRadius.chatBubble),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: const SizedBox(
        width: 36,
        height: 16,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}

// Mic SVG icon matching design
class _MicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // rect(9,3,6,12,rx3) → mic body centered in 16x16
    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(5, 0, 6, 10),
      const Radius.circular(3),
    );
    canvas.drawRRect(rrect, paint);

    // arc: M1 8 a7 7 0 0 0 14 0 → path from bottom of mic
    final path = Path()
      ..moveTo(0, 8)
      ..arcToPoint(
        const Offset(16, 8),
        radius: const Radius.circular(8),
        clockwise: false,
      );
    canvas.drawPath(path, stroke);

    // vertical line M8 15 v2
    canvas.drawLine(const Offset(8, 15), const Offset(8, 16), stroke);
  }

  @override
  bool shouldRepaint(_MicPainter _) => false;
}

