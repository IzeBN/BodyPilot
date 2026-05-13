import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AvatarButton extends StatelessWidget {
  final String initials;
  final VoidCallback? onTap;
  final double size;

  const AvatarButton({
    super.key,
    required this.initials,
    this.onTap,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppGradients.avatar,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.32,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
