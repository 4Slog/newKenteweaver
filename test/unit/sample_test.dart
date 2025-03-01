import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Basic math test', () {
    expect(2 + 2, equals(4));
  });

  test('String test', () {
    expect('Hello' + ' World', equals('Hello World'));
  });
}
