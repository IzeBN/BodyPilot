import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'recognition_result_sheet.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final String date;
  const BarcodeScannerScreen({super.key, required this.date});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _scanned = false;
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onBarcode(String barcode) async {
    if (_scanned || _loading) return;
    setState(() { _scanned = true; _loading = true; });
    await _ctrl.stop();

    try {
      final resp = await apiDio.get('/api/v2/barcode', queryParameters: {'code': barcode});
      if (!mounted) return;
      final items = (resp.data['items'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];
      if (items.isEmpty) {
        _showNotFound();
        return;
      }
      final dishName = resp.data['product_name'] as String? ??
          items.map((e) => e['name'] as String? ?? '').where((n) => n.isNotEmpty).join(', ');

      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.92, minChildSize: 0.5, maxChildSize: 0.95,
          builder: (_, __) => RecognitionResultSheet(date: widget.date, items: items, dishName: dishName),
        ),
      );
      if (mounted) Navigator.of(context).pop(saved == true);
    } catch (_) {
      _showNotFound();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showNotFound() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppL10n.of(context).barcodeNotFound),
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() => _scanned = false);
    _ctrl.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _ctrl,
            onDetect: (capture) {
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code != null) _onBarcode(code);
            },
          ),
          // Overlay
          CustomPaint(
            painter: _ScanOverlayPainter(),
            child: const SizedBox.expand(),
          ),
          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(19)),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _ctrl.toggleTorch(),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(19)),
                      child: const Icon(Icons.flashlight_on_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom label
          Align(
            alignment: const Alignment(0, 0.7),
            child: Text(
              AppL10n.of(context).barcodeScanHint,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    const sq = 260.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final left = cx - sq / 2;
    final top = cy - sq / 2;

    // Dark overlay minus scan window
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left, top, sq, sq), const Radius.circular(12)));
    canvas.drawPath(path..fillType = PathFillType.evenOdd, paint);

    // Corners
    final corner = Paint()..color = AppColors.brandBlue..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const len = 28.0;
    final corners = [
      [Offset(left, top + len), Offset(left, top), Offset(left + len, top)],
      [Offset(left + sq - len, top), Offset(left + sq, top), Offset(left + sq, top + len)],
      [Offset(left + sq, top + sq - len), Offset(left + sq, top + sq), Offset(left + sq - len, top + sq)],
      [Offset(left, top + sq - len), Offset(left, top + sq), Offset(left + len, top + sq)],
    ];
    for (final pts in corners) {
      final p = Path()..moveTo(pts[0].dx, pts[0].dy)..lineTo(pts[1].dx, pts[1].dy)..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(p, corner);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
