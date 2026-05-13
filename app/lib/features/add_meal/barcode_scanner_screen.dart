import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'recognition_result_sheet.dart';

enum _ScanState { scanning, loading, error }

class BarcodeScannerScreen extends StatefulWidget {
  final String date;
  const BarcodeScannerScreen({super.key, required this.date});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with TickerProviderStateMixin {
  late final MobileScannerController _ctrl;
  late final AnimationController _laserCtrl;
  late final Animation<double> _laserAnim;

  _ScanState _state = _ScanState.scanning;
  String _errorText = '';
  bool _torchOn = false;

  static const double _frameSize = 260.0;

  @override
  void initState() {
    super.initState();
    _ctrl = MobileScannerController();
    _laserCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _laserAnim = CurvedAnimation(parent: _laserCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _laserCtrl.dispose();
    super.dispose();
  }

  Future<void> _onBarcode(BarcodeCapture capture) async {
    if (_state != _ScanState.scanning) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    HapticFeedback.mediumImpact();
    await _lookupBarcode(code);
  }

  Future<void> _lookupBarcode(String code) async {
    setState(() => _state = _ScanState.loading);
    try {
      final resp = await apiDio.get('/api/v1/nutrition/foods/barcode/$code');
      if (!mounted) return;
      final food = resp.data as Map<String, dynamic>?;
      if (food == null || food['name'] == null) {
        setState(() {
          _state = _ScanState.error;
          _errorText = AppL10n.of(context).barcodeNotFound;
        });
        return;
      }

      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.92, minChildSize: 0.5, maxChildSize: 0.95,
          builder: (_, __) => RecognitionResultSheet(
            date: widget.date,
            items: [food],
            dishName: food['name'] as String? ?? '',
          ),
        ),
      );

      if (!mounted) return;
      if (saved == true) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _state = _ScanState.scanning);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = (e.response?.data is Map)
          ? ((e.response?.data as Map)['detail'] as String? ?? AppL10n.of(context).barcodeNotFound)
          : AppL10n.of(context).barcodeNotFound;
      setState(() { _state = _ScanState.error; _errorText = msg; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _state = _ScanState.error; _errorText = e.toString(); });
    }
  }

  Future<void> _showManualEntry() async {
    final ctrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: _ManualEntrySheet(
          controller: ctrl,
          onSearch: (code) {
            Navigator.of(sheetCtx).pop();
            _lookupBarcode(code);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frameCenterY = size.height / 2 - 40;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _ctrl, onDetect: _onBarcode),

          // Dark overlay with cutout
          CustomPaint(
            painter: _OverlayPainter(frameSize: _frameSize, centerY: frameCenterY),
          ),

          // Corner brackets + laser
          _ScanFrameDecor(
            frameSize: _frameSize,
            centerY: frameCenterY,
            showLaser: _state == _ScanState.scanning,
            laserAnim: _laserAnim,
          ),

          // Loading spinner inside frame
          if (_state == _ScanState.loading)
            Positioned(
              left: (size.width - _frameSize) / 2,
              top: frameCenterY - _frameSize / 2,
              width: _frameSize,
              height: _frameSize,
              child: const Center(
                child: SizedBox(
                  width: 44, height: 44,
                  child: CircularProgressIndicator(color: Color(0xFF38BDF8), strokeWidth: 3),
                ),
              ),
            ),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: _TopBar(
              torchOn: _torchOn,
              onBack: () => Navigator.of(context).pop(),
              onTorch: () async {
                await _ctrl.toggleTorch();
                setState(() => _torchOn = !_torchOn);
              },
            ),
          ),

          // Status text
          Positioned(
            top: frameCenterY + _frameSize / 2 + 24,
            left: 32, right: 32,
            child: _StatusText(
              state: _state,
              errorText: _errorText,
              hint: AppL10n.of(context).barcodeScanHint,
              onRetry: () => setState(() => _state = _ScanState.scanning),
            ),
          ),

          // Manual entry button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 40, right: 40,
            child: _ManualEntryButton(onTap: _showManualEntry),
          ),
        ],
      ),
    );
  }
}

// ── Overlay ───────────────────────────────────────────────────────────────────

class _OverlayPainter extends CustomPainter {
  final double frameSize;
  final double centerY;
  const _OverlayPainter({required this.frameSize, required this.centerY});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xCC000000));
    final left = (size.width - frameSize) / 2;
    final top = centerY - frameSize / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, top, frameSize, frameSize), const Radius.circular(16)),
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.frameSize != frameSize || old.centerY != centerY;
}

// ── Corner brackets + laser ───────────────────────────────────────────────────

class _ScanFrameDecor extends StatelessWidget {
  final double frameSize;
  final double centerY;
  final bool showLaser;
  final Animation<double> laserAnim;
  const _ScanFrameDecor({
    required this.frameSize, required this.centerY,
    required this.showLaser, required this.laserAnim,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final left = (screenWidth - frameSize) / 2;
    final top = centerY - frameSize / 2;
    return Stack(
      children: [
        Positioned(
          left: left, top: top,
          child: CustomPaint(
            size: Size(frameSize, frameSize),
            painter: _CornerBracketsPainter(),
          ),
        ),
        if (showLaser)
          AnimatedBuilder(
            animation: laserAnim,
            builder: (_, __) {
              final laserY = top + laserAnim.value * (frameSize - 2);
              return Positioned(
                left: left + 12, top: laserY,
                width: frameSize - 24, height: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Colors.transparent,
                      Color(0xCC38BDF8),
                      Color(0xFF38BDF8),
                      Color(0xCC38BDF8),
                      Colors.transparent,
                    ]),
                    boxShadow: [BoxShadow(color: const Color(0xFF38BDF8).withValues(alpha: 0.6), blurRadius: 6)],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  static const double _len = 28.0;
  static const double _r = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.brandBlue
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    const pi = math.pi;

    // Top-left
    canvas.drawLine(Offset(_r, 0), Offset(_r + _len, 0), paint);
    canvas.drawLine(Offset(0, _r), Offset(0, _r + _len), paint);
    canvas.drawArc(Rect.fromLTWH(0, 0, _r * 2, _r * 2), pi, pi / 2, false, paint);

    // Top-right
    canvas.drawLine(Offset(w - _r - _len, 0), Offset(w - _r, 0), paint);
    canvas.drawLine(Offset(w, _r), Offset(w, _r + _len), paint);
    canvas.drawArc(Rect.fromLTWH(w - _r * 2, 0, _r * 2, _r * 2), pi * 1.5, pi / 2, false, paint);

    // Bottom-left
    canvas.drawLine(Offset(_r, h), Offset(_r + _len, h), paint);
    canvas.drawLine(Offset(0, h - _r - _len), Offset(0, h - _r), paint);
    canvas.drawArc(Rect.fromLTWH(0, h - _r * 2, _r * 2, _r * 2), pi / 2, pi / 2, false, paint);

    // Bottom-right
    canvas.drawLine(Offset(w - _r - _len, h), Offset(w - _r, h), paint);
    canvas.drawLine(Offset(w, h - _r - _len), Offset(w, h - _r), paint);
    canvas.drawArc(Rect.fromLTWH(w - _r * 2, h - _r * 2, _r * 2, _r * 2), 0, pi / 2, false, paint);
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter _) => false;
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool torchOn;
  final VoidCallback onBack;
  final VoidCallback onTorch;
  const _TopBar({required this.torchOn, required this.onBack, required this.onTorch});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(8, topPad + 4, 8, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(
              AppL10n.of(context).barcodeScanHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: onTorch,
            icon: Icon(
              torchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
              color: torchOn ? const Color(0xFF38BDF8) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status text ───────────────────────────────────────────────────────────────

class _StatusText extends StatelessWidget {
  final _ScanState state;
  final String errorText;
  final String hint;
  final VoidCallback onRetry;
  const _StatusText({required this.state, required this.errorText,
      required this.hint, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      _ScanState.scanning => Text(hint,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      _ScanState.loading => Text(AppL10n.of(context).barcodeLoading,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 15, fontWeight: FontWeight.w500)),
      _ScanState.error => Column(children: [
          Text(errorText, textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Text(AppL10n.of(context).retryLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
        ]),
    };
  }
}

// ── Manual entry button ───────────────────────────────────────────────────────

class _ManualEntryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ManualEntryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            alignment: Alignment.center,
            child: Text(AppL10n.of(context).barcodeManualHint,
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

// ── Manual entry sheet ────────────────────────────────────────────────────────

class _ManualEntrySheet extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String code) onSearch;
  const _ManualEntrySheet({required this.controller, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.borderStrong, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(AppL10n.of(context).barcodeManualTitle, style: const TextStyle(fontSize: 18,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3)),
          const SizedBox(height: 4),
          Text(AppL10n.of(context).barcodeManualFormats,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 20,
            decoration: InputDecoration(
              hintText: AppL10n.of(context).barcodeManualPlaceholder,
              prefixIcon: const Icon(Icons.qr_code_rounded, color: AppColors.textMuted, size: 20),
              counterText: '',
              filled: true, fillColor: AppColors.surfaceTint,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderStrong)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderStrong)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.brandBlue, width: 2)),
            ),
            onSubmitted: (v) { if (v.trim().isNotEmpty) onSearch(v.trim()); },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                final t = controller.text.trim();
                if (t.isNotEmpty) onSearch(t);
              },
              child: Text(AppL10n.of(context).barcodeSearch, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
