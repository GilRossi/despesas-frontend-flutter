import 'package:despesas_frontend/app/app_theme.dart';
import 'package:despesas_frontend/core/ui/components/app_scaffold.dart';
import 'package:despesas_frontend/core/ui/components/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppScaffold renders header and body with SectionCard', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: const AppScaffold(
        title: 'Titulo',
        subtitle: 'Sub',
        body: SectionCard(child: Text('conteudo')),
      ),
    ));

    expect(find.text('Titulo'), findsOneWidget);
    expect(find.text('Sub'), findsOneWidget);
    expect(find.text('conteudo'), findsOneWidget);
  });
}
