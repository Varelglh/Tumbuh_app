import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';

class TumbuhHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onProfileTap;

  const TumbuhHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(999),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.brandGreen.withOpacity(0.12),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Image.asset(
                'assets/icons/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppTheme.brandGreen,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: AppTheme.muted),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
