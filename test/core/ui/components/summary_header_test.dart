import 'package:despesas_frontend/core/ui/components/summary_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('summary header trunca titulo e subtitulo no app bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const SummaryHeader(
              title: 'Cadastrar conta fixa com um titulo bem mais longo',
              subtitle: 'Teste Owner com subtitulo igualmente mais longo',
            ),
          ),
        ),
      ),
    );

    final titleText = tester.widget<Text>(
      find.text('Cadastrar conta fixa com um titulo bem mais longo'),
    );
    final subtitleText = tester.widget<Text>(
      find.text('Teste Owner com subtitulo igualmente mais longo'),
    );

    expect(titleText.maxLines, 1);
    expect(titleText.overflow, TextOverflow.ellipsis);
    expect(subtitleText.maxLines, 1);
    expect(subtitleText.overflow, TextOverflow.ellipsis);
  });
}
