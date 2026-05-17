import 'package:flutter/material.dart';

class TumbuhSearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final BorderRadius borderRadius;

  const TumbuhSearchField({
    super.key,
    required this.hintText,
    this.onChanged,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
