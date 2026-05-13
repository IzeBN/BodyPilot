import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../providers/auth_api_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authApiProvider).login(_emailCtrl.text.trim(), _passCtrl.text);
    } catch (e) {
      if (mounted) setState(() { _error = AppL10n.of(context).loginError; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),
              Text(l.loginTitle, style: AppText.appBarTitle()),
              const SizedBox(height: 8),
              Text(l.loginSubtitle, style: AppText.meta12()),
              const SizedBox(height: 32),
              _Field(controller: _emailCtrl, hint: l.emailHint, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _Field(controller: _passCtrl, hint: l.passwordHint, obscure: true),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: l.loginButton,
                onPressed: _loading ? null : _login,
                loading: _loading,
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => context.push('/register'),
                  child: Text(
                    l.noAccount,
                    style: AppText.meta12(color: AppColors.brandBlue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: AppText.bodyName(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.bodyName(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceTint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
