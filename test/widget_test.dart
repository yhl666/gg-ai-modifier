import 'package:flutter_test/flutter_test.dart';
import 'package:ai_gg666/app.dart';

void main() {
  testWidgets('App launches correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const GgModifierApp());
    await tester.pumpAndSettle();

    // 验证 AI 对话页面标题存在
    expect(find.text('GG-AI 助手'), findsOneWidget);
  });
}
