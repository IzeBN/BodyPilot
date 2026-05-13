import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class ShellScaffold extends StatelessWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final today = DateTime.now().toIso8601String().substring(0, 10);
          context.push('/add-meal?date=$today');
        },
        backgroundColor: AppColors.brandBlue,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Text('+', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300, height: 1)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final isJournal = location == '/journal';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderStrong, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: _JournalIcon(active: isJournal),
                  label: l.tabJournal,
                  active: isJournal,
                  onTap: () => context.go('/journal'),
                ),
              ),
              const SizedBox(width: 72),
              Expanded(
                child: _NavItem(
                  icon: _ChatIcon(active: !isJournal),
                  label: l.tabChat,
                  active: !isJournal,
                  onTap: () => context.go('/chat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brandBlue : AppColors.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}

// ── Custom SVG icons ──────────────────────────────────────────────────────────

class _JournalIcon extends StatelessWidget {
  final bool active;
  const _JournalIcon({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brandBlue : AppColors.textMuted;
    return CustomPaint(size: const Size(24, 24), painter: _JournalIconPainter(color));
  }
}

class _JournalIconPainter extends CustomPainter {
  final Color color;
  _JournalIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(3, 3, 18, 18), const Radius.circular(2)),
      paint,
    );
    canvas.drawLine(const Offset(3, 9), const Offset(21, 9), paint);
    canvas.drawLine(const Offset(9, 9), const Offset(9, 21), paint);
  }

  @override
  bool shouldRepaint(_JournalIconPainter old) => old.color != color;
}

class _ChatIcon extends StatelessWidget {
  final bool active;
  const _ChatIcon({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brandBlue : AppColors.textMuted;
    return CustomPaint(size: const Size(24, 24), painter: _ChatIconPainter(color));
  }
}

class _ChatIconPainter extends CustomPainter {
  final Color color;
  _ChatIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(21, 15)
      ..arcToPoint(const Offset(19, 17), radius: const Radius.circular(2), clockwise: false)
      ..lineTo(7, 17)
      ..lineTo(3, 21)
      ..lineTo(3, 5)
      ..arcToPoint(const Offset(5, 3), radius: const Radius.circular(2), clockwise: true)
      ..lineTo(19, 3)
      ..arcToPoint(const Offset(21, 5), radius: const Radius.circular(2), clockwise: true)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChatIconPainter old) => old.color != color;
}
