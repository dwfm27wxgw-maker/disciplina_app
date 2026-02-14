// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'app_theme.dart';

class DCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const DCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: child,
    );
  }
}

class DPill extends StatelessWidget {
  final String text;
  final Color? bg;
  final Color? fg;
  final EdgeInsets padding;

  const DPill(
    this.text, {
    super.key,
    this.bg,
    this.fg,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg ?? Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg ?? AppTheme.muted,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class DTitle extends StatelessWidget {
  final String text;
  final double size;

  const DTitle(this.text, {super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.text,
        fontSize: size,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class DText extends StatelessWidget {
  final String text;
  final int? maxLines;

  const DText(this.text, {super.key, this.maxLines});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: const TextStyle(
        color: AppTheme.text,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class DMuted extends StatelessWidget {
  final String text;
  final int? maxLines;

  const DMuted(this.text, {super.key, this.maxLines});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: const TextStyle(
        color: AppTheme.muted,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class DDivider extends StatelessWidget {
  const DDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(color: Colors.white.withOpacity(0.08), height: 22);
  }
}
