import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitmovelab/app.dart';

void main() {
  testWidgets('App boots to the welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitMoveLabApp()));
    await tester.pumpAndSettle();

    expect(find.text('FitMoveLab'), findsOneWidget);
    expect(find.text("Let's get started"), findsOneWidget);
  });
}
