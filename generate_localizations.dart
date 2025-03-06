// A simple script to generate localization files from ARB files

import 'dart:io';

void main() async {
  print('Generating localization files...');
  
  // Create the output directory if it doesn't exist
  final outputDir = Directory('lib/l10n/generated');
  if (!await outputDir.exists()) {
    await outputDir.create(recursive: true);
  }
  
  // Run the intl_translation command
  final result = await Process.run(
    'dart',
    [
      'run',
      'intl_translation:generate_from_arb',
      '--output-dir=lib/l10n/generated',
      '--no-use-deferred-loading',
      'lib/l10n/messages.dart',
      'lib/l10n/app_en.arb',
      'lib/l10n/app_fr.arb',
      'lib/l10n/app_tw.arb',
      'lib/l10n/app_ha.arb'
    ],
  );
  
  print(result.stdout);
  if (result.stderr.toString().isNotEmpty) {
    print('Error: ${result.stderr}');
  }
  
  print('Done!');
}
