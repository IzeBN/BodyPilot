import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum AppButtonVariant { blue, coral, outline }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.blue,
    this.loading = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : null,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (variant) {
      case AppButtonVariant.blue:
        return _BlueButton(label: label, onPressed: onPressed, loading: loading);
      case AppButtonVariant.coral:
        return _CoralButton(label: label, onPressed: onPressed, loading: loading);
      case AppButtonVariant.outline:
        return _OutlineButton(label: label, onPressed: onPressed, loading: loading);
    }
  }
}

class _BlueButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const _BlueButton({required this.label, this.onPressed, required this.loading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: AnimatedOpacity(
        opacity: onPressed == null ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.brandBlue,
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandBlue.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(label, style: AppText.btn()),
          ),
        ),
      ),
    );
  }
}

class _CoralButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const _CoralButton({required this.label, this.onPressed, required this.loading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppGradients.btnCoral,
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: [
            BoxShadow(
              color: AppColors.coralEnd.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(label, style: AppText.btn()),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const _OutlineButton({required this.label, this.onPressed, required this.loading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.borderStrong, width: 1.5),
        ),
        child: Center(
          child: Text(label, style: AppText.btn(color: AppColors.textPrimary)),
        ),
      ),
    );
  }
}
