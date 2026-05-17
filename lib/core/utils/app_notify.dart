import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';

enum AppNotifyType { info, success, error }

class AppNotify {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    AppNotifyType type = AppNotifyType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final String msg = message.trim();
    if (msg.isEmpty) return;

    final overlay = Overlay.of(context, rootOverlay: true);

    _timer?.cancel();
    _timer = null;

    _entry?.remove();
    _entry = null;

    final Color accent = switch (type) {
      AppNotifyType.success => AppTheme.brandGreen,
      AppNotifyType.error => Colors.red,
      AppNotifyType.info => AppTheme.brandGreenDark,
    };

    _entry = OverlayEntry(
      builder: (ctx) {
        final double top = MediaQuery.of(ctx).padding.top + 12;
        return Positioned(
          top: top,
          left: 16,
          right: 16,
          child: IgnorePointer(
            ignoring: false,
            child: Material(
              color: Colors.transparent,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOut,
                    builder: (context, t, child) {
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * -10),
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: hide,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: accent.withOpacity(0.18)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                msg,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);

    _timer = Timer(duration, hide);
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;

    _entry?.remove();
    _entry = null;
  }
}
