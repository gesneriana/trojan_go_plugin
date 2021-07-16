import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trojangoplugin/trojangoplugin.dart';

void main() {
  const MethodChannel channel = MethodChannel('trojangoplugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await Trojangoplugin.platformVersion, '42');
  });
}
