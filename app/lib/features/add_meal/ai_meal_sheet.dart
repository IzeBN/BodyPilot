import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'barcode_scanner_screen.dart';
import 'recognition_result_sheet.dart';

enum _Mode { choose, text, voice, photo }
enum _Loading { none, voice, photo, parsing }

class AiMealSheet extends StatefulWidget {
  final String date;
  const AiMealSheet({super.key, required this.date});

  @override
  State<AiMealSheet> createState() => _AiMealSheetState();
}

class _AiMealSheetState extends State<AiMealSheet> with TickerProviderStateMixin {
  _Mode _mode = _Mode.choose;
  _Loading _loading = _Loading.none;

  final _textCtrl = TextEditingController();
  final _textFocus = FocusNode();

  final _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordPath;
  DateTime? _recordStart;

  late final AnimationController _sheetCtrl;
  late final Animation<double> _sheetFade;
  late final Animation<Offset> _sheetSlide;
  late final AnimationController _modeCtrl;

  @override
  void initState() {
    super.initState();
    _sheetCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _sheetFade = CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic);
    _sheetSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic));
    _modeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280))..value = 1.0;
    _sheetCtrl.forward();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _textFocus.dispose();
    _recorder.dispose();
    _sheetCtrl.dispose();
    _modeCtrl.dispose();
    super.dispose();
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  Future<void> _switchMode(_Mode mode) async {
    HapticFeedback.selectionClick();
    await _modeCtrl.reverse();
    setState(() => _mode = mode);
    _modeCtrl.forward();
    if (mode == _Mode.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _textFocus.requestFocus());
    }
  }

  // ── Text parsing ──────────────────────────────────────────────────────────

  Future<void> _parseText(String text, {bool manageLoading = true}) async {
    if (manageLoading) setState(() => _loading = _Loading.parsing);
    try {
      final resp = await apiDio.post(
        '/api/v1/nutrition/recognize/text',
        data: {'text': text, 'language': _lang},
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      );
      final rawItems = (resp.data['items'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];
      if (!mounted) return;
      if (rawItems.isNotEmpty) {
        if (manageLoading) setState(() => _loading = _Loading.none);
        final saved = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.92, minChildSize: 0.5, maxChildSize: 0.95,
            builder: (_, __) => RecognitionResultSheet(
              date: widget.date,
              items: rawItems,
              dishName: rawItems.map((e) => e['name'] as String? ?? '').where((n) => n.isNotEmpty).join(', '),
            ),
          ),
        );
        if (saved == true && mounted) Navigator.of(context).pop();
        return;
      }
    } catch (e) {
      _showError();
    } finally {
      if (manageLoading && mounted) setState(() => _loading = _Loading.none);
    }
  }

  // ── Voice ─────────────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      _showError(msg: AppL10n.of(context).micNoAccess);
      _switchMode(_Mode.choose);
      return;
    }
    final dir = await getTemporaryDirectory();
    _recordPath = '${dir.path}/meal_voice.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: _recordPath!);
    _recordStart = DateTime.now();
    if (mounted) setState(() => _isRecording = true);
  }

  Future<void> _stopAndTranscribe() async {
    await _recorder.stop();
    setState(() { _isRecording = false; _loading = _Loading.voice; });
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(_recordPath!, filename: 'voice.m4a'),
        'language': _lang,
      });
      final resp = await apiDio.post('/api/v1/nutrition/recognize/voice', data: form);
      final raw = resp.data;
      if (raw is! Map) throw Exception('unexpected response');
      final rawItems = (raw['items'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];
      if (!mounted) return;
      if (rawItems.isNotEmpty) {
        if (mounted) setState(() => _loading = _Loading.none);
        final dishName = rawItems
            .map((e) => e['name'] as String? ?? '')
            .where((n) => n.isNotEmpty)
            .join(', ');
        final saved = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.92, minChildSize: 0.5, maxChildSize: 0.95,
            builder: (_, __) => RecognitionResultSheet(
              date: widget.date, items: rawItems, dishName: dishName),
          ),
        );
        if (saved == true && mounted) Navigator.of(context).pop();
        return;
      }
      // Fallback: re-parse from transcript if items are empty
      final transcript = raw['transcript'] as String? ?? '';
      if (transcript.isNotEmpty) {
        await _parseText(transcript, manageLoading: false);
      } else if (mounted) {
        _switchMode(_Mode.choose);
      }
    } catch (_) {
      _showError();
      if (mounted) _switchMode(_Mode.choose);
    } finally {
      if (mounted) setState(() => _loading = _Loading.none);
    }
  }

  // ── Photo ─────────────────────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _loading = _Loading.photo);
    final lang = _lang;
    final file = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (file == null) {
      if (mounted) { setState(() => _loading = _Loading.none); _switchMode(_Mode.choose); }
      return;
    }
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        file.path, minWidth: 1280, minHeight: 1280, quality: 75, format: CompressFormat.jpeg,
      );
      late final MultipartFile multipart;
      if (compressed != null) {
        multipart = MultipartFile.fromBytes(compressed, filename: 'photo.jpg',
            contentType: DioMediaType('image', 'jpeg'));
      } else {
        multipart = await MultipartFile.fromFile(file.path, filename: 'photo.jpg',
            contentType: DioMediaType('image', 'jpeg'));
      }
      final resp = await apiDio.post(
        '/api/v1/nutrition/recognize/photo',
        data: FormData.fromMap({'file': multipart, 'language': lang}),
        options: Options(receiveTimeout: const Duration(seconds: 120), sendTimeout: const Duration(seconds: 60)),
      );
      if (!mounted) return;
      final rawItems = resp.data['items'] as List<dynamic>?;
      if (rawItems == null || rawItems.isEmpty) {
        setState(() => _loading = _Loading.none);
        _showError(msg: AppL10n.of(context).recognizePhotoError);
        return;
      }
      final items = rawItems.map((e) => e as Map<String, dynamic>).toList();
      final dishName = resp.data['dish_name'] as String? ??
          items.map((e) => e['name'] as String? ?? '').where((n) => n.isNotEmpty).join(', ');
      setState(() => _loading = _Loading.none);
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.92, minChildSize: 0.5, maxChildSize: 0.95,
          builder: (_, __) => RecognitionResultSheet(date: widget.date, items: items, dishName: dishName),
        ),
      );
      if (saved == true && mounted) Navigator.of(context).pop();
    } catch (_) {
      _showError();
    } finally {
      if (mounted) setState(() => _loading = _Loading.none);
    }
  }

  // ── Barcode ───────────────────────────────────────────────────────────────

  Future<void> _openBarcode() async {
    HapticFeedback.selectionClick();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BarcodeScannerScreen(date: widget.date)),
    );
    if (saved == true && mounted) Navigator.of(context).pop();
  }

  void _showError({String? msg}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg ?? AppL10n.of(context).errorGeneric),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.calories,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    return FadeTransition(
      opacity: _sheetFade,
      child: SlideTransition(
        position: _sheetSlide,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grab
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    decoration: BoxDecoration(color: AppColors.borderStrong, borderRadius: BorderRadius.circular(2)),
                  ),
                  // Header
                  _Header(
                    mode: _mode,
                    onBack: _mode != _Mode.choose ? () => _switchMode(_Mode.choose) : null,
                  ),
                  // Body
                  FadeTransition(
                    opacity: _modeCtrl,
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 20),
                        child: _buildBody(),
                      ),
                    ),
                  ),
                ],
              ),
              if (_loading == _Loading.voice || _loading == _Loading.photo)
                _RecognizingOverlay(isVoice: _loading == _Loading.voice),
              if (_loading == _Loading.parsing)
                const _ParsingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_mode) {
      case _Mode.choose:
        return _ChooseView(
          onText: () => _switchMode(_Mode.text),
          onVoice: () async {
            await _switchMode(_Mode.voice);
            await Future.delayed(const Duration(milliseconds: 350));
            await _startRecording();
          },
          onPhoto: () async {
            final source = await showModalBottomSheet<ImageSource>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => const _PhotoSourceSheet(),
            );
            if (source == null) return;
            await _switchMode(_Mode.photo);
            if (!mounted) return;
            await _pickPhoto(source);
          },
          onBarcode: _openBarcode,
        );
      case _Mode.text:
        return _TextView(
          controller: _textCtrl,
          focus: _textFocus,
          onParse: () => _parseText(_textCtrl.text),
        );
      case _Mode.voice:
        return _VoiceView(
          isRecording: _isRecording,
          recordStart: _recordStart,
          onToggle: _isRecording ? _stopAndTranscribe : _startRecording,
        );
      case _Mode.photo:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final _Mode mode;
  final VoidCallback? onBack;
  const _Header({required this.mode, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(color: AppColors.surfaceTint, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              l.addFoodTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.3),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Choose view
// ─────────────────────────────────────────────────────────────────────────────

class _ChooseView extends StatefulWidget {
  final VoidCallback onText;
  final VoidCallback onVoice;
  final VoidCallback onPhoto;
  final VoidCallback onBarcode;
  const _ChooseView({required this.onText, required this.onVoice, required this.onPhoto, required this.onBarcode});

  @override
  State<_ChooseView> createState() => _ChooseViewState();
}

class _ChooseViewState extends State<_ChooseView> with SingleTickerProviderStateMixin {
  late final AnimationController _stagger;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
  }

  @override
  void dispose() { _stagger.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final methods = [
      _MethodData(emoji: '📸', title: '📸 ${l.methodPhotoTitle}', desc: l.methodPhotoDesc, onTap: widget.onPhoto),
      _MethodData(emoji: '🎙️', title: '🎙️ ${l.methodVoiceTitle}', desc: l.methodVoiceDesc, onTap: widget.onVoice),
      _MethodData(emoji: '✏️', title: '✏️ ${l.methodTextTitle}', desc: l.methodTextDesc, onTap: widget.onText),
      _MethodData(emoji: '📱', title: '📱 ${l.methodBarcodeTitle}', desc: l.methodBarcodeDesc, onTap: widget.onBarcode),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: methods.asMap().entries.map((e) {
        final delay = e.key * 0.15;
        final fade = CurvedAnimation(parent: _stagger, curve: Interval(delay, delay + 0.5, curve: Curves.easeOutCubic));
        final slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
            .animate(CurvedAnimation(parent: _stagger, curve: Interval(delay, delay + 0.5, curve: Curves.easeOutCubic)));
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: _MethodTile(data: e.value)),
          ),
        );
      }).toList(),
    );
  }
}

class _MethodData {
  final String emoji;
  final String title;
  final String desc;
  final VoidCallback onTap;
  const _MethodData({required this.emoji, required this.title, required this.desc, required this.onTap});
}

class _MethodTile extends StatefulWidget {
  final _MethodData data;
  const _MethodTile({required this.data});

  @override
  State<_MethodTile> createState() => _MethodTileState();
}

class _MethodTileState extends State<_MethodTile> with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 110), lowerBound: 0.96, upperBound: 1.0, value: 1.0);
  }

  @override
  void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return ScaleTransition(
      scale: _press,
      child: GestureDetector(
        onTapDown: (_) => _press.reverse(),
        onTapUp: (_) { _press.forward(); d.onTap(); },
        onTapCancel: () => _press.forward(),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: [BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF34D399)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Center(child: Text(d.emoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.2)),
                    const SizedBox(height: 3),
                    Text(d.desc, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF059669)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text view
// ─────────────────────────────────────────────────────────────────────────────

class _TextView extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onParse;
  const _TextView({required this.controller, required this.focus, required this.onParse});

  @override
  State<_TextView> createState() => _TextViewState();
}

class _TextViewState extends State<_TextView> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() { widget.controller.removeListener(_onChanged); super.dispose(); }

  void _onChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final hints = ru
        ? ['Гречка 200г, курица 150г', 'Борщ 300мл, хлеб 2 куска']
        : ['Oatmeal 200g, chicken 150g', 'Soup 300ml, 2 bread slices'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8, runSpacing: 6,
          children: hints.map((h) => GestureDetector(
            onTap: () { widget.controller.text = h; widget.focus.requestFocus(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
              ),
              child: Text(h, style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w500)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceTint, borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focus,
            maxLines: 4, minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l.textInputHint,
              border: InputBorder.none, filled: false,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.5),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedOpacity(
          opacity: _hasText ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            width: double.infinity, height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _hasText
                    ? const LinearGradient(colors: [Color(0xFF059669), Color(0xFF16A34A)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : const LinearGradient(colors: [AppColors.borderStrong, AppColors.borderStrong]),
                borderRadius: BorderRadius.circular(AppRadius.button),
                boxShadow: _hasText ? [BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: InkWell(
                  onTap: _hasText ? widget.onParse : null,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  child: Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(AppL10n.of(context).aiRecognize, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Voice view
// ─────────────────────────────────────────────────────────────────────────────

class _VoiceView extends StatefulWidget {
  final bool isRecording;
  final DateTime? recordStart;
  final VoidCallback onToggle;
  const _VoiceView({required this.isRecording, required this.recordStart, required this.onToggle});

  @override
  State<_VoiceView> createState() => _VoiceViewState();
}

class _VoiceViewState extends State<_VoiceView> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _wave;
  late final AnimationController _timerCtrl;
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
    _timerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(() {
        if (widget.isRecording && widget.recordStart != null) {
          setState(() => _elapsed = DateTime.now().difference(widget.recordStart!).inSeconds);
        }
      })
      ..repeat();
  }

  @override
  void dispose() { _pulse.dispose(); _wave.dispose(); _timerCtrl.dispose(); super.dispose(); }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(1, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final rec = widget.isRecording;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rec ? l.voiceRecordingTitle : l.voiceInputTitle,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: rec ? AppColors.calories : AppColors.textMuted),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 200, height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (int i = 0; i < (rec ? 3 : 2); i++)
                  _RippleRing(ctrl: _pulse, delay: i * (rec ? 0.33 : 0.5), color: rec ? AppColors.calories : AppColors.brandBlue),
                GestureDetector(
                  onTap: widget.onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300), curve: Curves.easeOutBack,
                    width: rec ? 88 : 80, height: rec ? 88 : 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: rec ? [const Color(0xFFDC2626), const Color(0xFFEF4444)] : [const Color(0xFF059669), const Color(0xFF10B981)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: (rec ? AppColors.calories : const Color(0xFF059669)).withValues(alpha: 0.45), blurRadius: 20, offset: const Offset(0, 6))],
                    ),
                    child: Icon(rec ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 38),
                  ),
                ),
              ],
            ),
          ),
          AnimatedOpacity(
            opacity: rec ? 1.0 : 0.0, duration: const Duration(milliseconds: 300),
            child: Text(_fmt(_elapsed), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 2)),
          ),
          const SizedBox(height: 12),
          if (rec)
            AnimatedBuilder(
              animation: _wave,
              builder: (_, __) => _WaveformBars(t: _wave.value),
            ),
          const SizedBox(height: 8),
          Text(
            rec ? l.voiceHintStop : l.voiceHintStart,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RippleRing extends StatelessWidget {
  final AnimationController ctrl;
  final double delay;
  final Color color;
  const _RippleRing({required this.ctrl, required this.delay, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ((ctrl.value + delay) % 1.0);
        final radius = 90.0 * t;
        final opacity = (1.0 - t) * 0.35;
        return Container(
          width: radius * 2, height: radius * 2,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: opacity), width: 2)),
        );
      },
    );
  }
}

class _WaveformBars extends StatelessWidget {
  final double t;
  const _WaveformBars({required this.t});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200, height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(24, (i) {
          final phase = (i / 24) * 2 * math.pi;
          final h = 4.0 + 22.0 * (0.5 + 0.5 * math.sin(t * 2 * math.pi + phase) * math.sin(i * 0.4));
          return Container(
            width: 3, height: h,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(color: AppColors.calories.withValues(alpha: 0.7 + 0.3 * (h / 26)), borderRadius: BorderRadius.circular(2)),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading overlays
// ─────────────────────────────────────────────────────────────────────────────

class _RecognizingOverlay extends StatefulWidget {
  final bool isVoice;
  const _RecognizingOverlay({required this.isVoice});

  @override
  State<_RecognizingOverlay> createState() => _RecognizingOverlayState();
}

class _RecognizingOverlayState extends State<_RecognizingOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final colors = widget.isVoice
        ? [const Color(0xFF059669), const Color(0xFF10B981)]
        : [const Color(0xFF7C3AED), const Color(0xFFA855F7)];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final scale = 1.0 + 0.08 * math.sin(_ctrl.value * 2 * math.pi);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: Icon(widget.isVoice ? Icons.graphic_eq_rounded : Icons.camera_enhance_rounded, color: Colors.white, size: 44),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            widget.isVoice ? l.recognizingVoice : l.recognizingPhoto,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.2),
          ),
          const SizedBox(height: 6),
          Text(AppL10n.of(context).aiDetermines, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i / 3.0;
                final t = ((_ctrl.value - delay) % 1.0 + 1.0) % 1.0;
                final scale = 0.5 + 0.5 * math.sin(t * math.pi);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Transform.scale(scale: scale, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: colors.first, shape: BoxShape.circle))),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParsingOverlay extends StatefulWidget {
  const _ParsingOverlay();

  @override
  State<_ParsingOverlay> createState() => _ParsingOverlayState();
}

class _ParsingOverlayState extends State<_ParsingOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Timer? _timer;
  int _visible = 1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
    _timer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (mounted && _visible < 4) setState(() => _visible++);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final steps = [l.parsingStep1, l.parsingStep2, l.parsingStep3, l.parsingStep4];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => Transform.scale(
                  scale: 1.0 + 0.07 * math.sin(_ctrl.value * 2 * math.pi),
                  child: Container(
                    width: 52, height: 52,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.manage_search_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.analyzingTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(AppL10n.of(context).aiDetermines, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ]),
            ]),
            const SizedBox(height: 32),
            ...List.generate(steps.length, (i) {
              final visible = i < _visible;
              final current = i == _visible - 1;
              final done = i < _visible - 1;
              return AnimatedOpacity(
                opacity: visible ? 1.0 : 0.0, duration: const Duration(milliseconds: 450),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(children: [
                    SizedBox(
                      width: 22, height: 22,
                      child: current
                          ? AnimatedBuilder(animation: _ctrl, builder: (_, __) => const CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF059669)))
                          : Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 22, color: done ? const Color(0xFF059669) : AppColors.borderStrong),
                    ),
                    const SizedBox(width: 14),
                    Text(steps[i], style: TextStyle(fontSize: 14, fontWeight: current ? FontWeight.w600 : FontWeight.w500, color: current ? AppColors.textPrimary : done ? AppColors.textMuted : AppColors.borderStrong)),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo source sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.borderStrong, borderRadius: BorderRadius.circular(2))),
          Text(l.photoSourceTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _SrcBtn(icon: Icons.camera_alt_rounded, gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFA855F7)]), label: l.photoCamera, onTap: () => Navigator.pop(context, ImageSource.camera)),
          const SizedBox(height: 10),
          _SrcBtn(icon: Icons.photo_library_rounded, gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)]), label: l.photoGallery, onTap: () => Navigator.pop(context, ImageSource.gallery)),
          const SizedBox(height: 6),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel, style: const TextStyle(color: AppColors.textMuted, fontSize: 15))),
        ],
      ),
    );
  }
}

class _SrcBtn extends StatelessWidget {
  final IconData icon;
  final LinearGradient gradient;
  final String label;
  final VoidCallback onTap;
  const _SrcBtn({required this.icon, required this.gradient, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(AppRadius.button)),
        child: Row(children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        ]),
      ),
    );
  }
}
