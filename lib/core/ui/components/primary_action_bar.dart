import 'package:flutter/material.dart';

class PrimaryActionBar extends StatelessWidget {
  const PrimaryActionBar({
    super.key,
    required this.primary,
    this.secondary,
    this.alignment = MainAxisAlignment.end,
  });

  final Widget primary;
  final Widget? secondary;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: _wrapAlignment(alignment),
      spacing: 12,
      runSpacing: 12,
      children: [?secondary, primary],
    );
  }

  WrapAlignment _wrapAlignment(MainAxisAlignment value) {
    return switch (value) {
      MainAxisAlignment.start => WrapAlignment.start,
      MainAxisAlignment.center => WrapAlignment.center,
      MainAxisAlignment.end => WrapAlignment.end,
      MainAxisAlignment.spaceBetween => WrapAlignment.spaceBetween,
      MainAxisAlignment.spaceAround => WrapAlignment.spaceAround,
      MainAxisAlignment.spaceEvenly => WrapAlignment.spaceEvenly,
    };
  }
}
