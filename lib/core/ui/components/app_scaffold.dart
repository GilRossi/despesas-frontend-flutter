import 'package:despesas_frontend/core/ui/components/summary_header.dart';
import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget body;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null || subtitle != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      appBar: hasHeader
          ? AppBar(
              titleSpacing: 0,
              title: SummaryHeader(title: title, subtitle: subtitle),
              actions: actions,
            )
          : AppBar(actions: actions),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Padding(
          padding: padding,
          child: body,
        ),
      ),
    );
  }
}
