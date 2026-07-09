import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend_flutter/main.dart';

void main() {
  testWidgets('MaraPlus app loads welcome screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaraPlusApp()));
    await tester.pumpAndSettle();

    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Bienvenido a MaraPlus'), findsOneWidget);
  });
}
