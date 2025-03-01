import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kente_codeweaver/app.dart';
import 'package:kente_codeweaver/providers/language_provider.dart';
import 'package:kente_codeweaver/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ],
        child: const KenteCodeWeaverApp(),
      ),
    );
    expect(find.text('Kente Code Weaver'), findsOneWidget);
  });
}
