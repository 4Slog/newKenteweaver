import 'package:flutter_test/flutter_test.dart';
import 'package:kente_codeweaver/app.dart';
import 'package:kente_codeweaver/providers/language_provider.dart';
import 'package:kente_codeweaver/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App should launch without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ],
        child: const KenteCodeWeaverApp(),
      ),
    );

    // Verify that the app starts with the welcome screen`
    expect(find.text('Kente Code Weaver'), findsOneWidget);
    
    // Wait for animations to complete
    await tester.pumpAndSettle();
  });
}
