import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend_flutter/main.dart';

void main() {
  testWidgets('Farma Express app loads welcome screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaraPlusApp()));
    await tester.pumpAndSettle();

    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Bienvenido a Farma Express'), findsOneWidget);
  });
}
