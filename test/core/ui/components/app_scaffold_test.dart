import 'package:despesas_frontend/core/ui/components/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app scaffold mantem cabecalho utilizavel em largura estreita', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));

    await tester.pumpWidget(
      const MaterialApp(
        home: AppScaffold(
          title: 'Editar conta fixa',
          subtitle: 'Teste Owner',
          actions: [
            IconButton(
              onPressed: null,
              icon: Icon(Icons.menu),
            ),
            IconButton(
              onPressed: null,
              icon: Icon(Icons.logout),
            ),
          ],
          body: SizedBox.shrink(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
