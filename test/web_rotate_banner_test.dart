import 'package:depthline_fleet/ui/web_rotate_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WebRotateBanner renders guidance text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WebRotateBanner(),
        ),
      ),
    );

    expect(find.text('WEB版は横向き推奨'), findsOneWidget);
    expect(
      find.text('スマホを横向きにすると、操作ボタンとレーダーが見やすくなります。'),
      findsOneWidget,
    );
  });
}
