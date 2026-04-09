import 'package:despesas_frontend/core/ui/components/primary_action_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('primary action bar nao estoura em largura estreita', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: PrimaryActionBar(
                secondary: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Voltar ao dashboard'),
                ),
                primary: FilledButton(
                  onPressed: () {},
                  child: const Text('Confirmar pagamento agora'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
