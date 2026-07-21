import 'package:flutter_test/flutter_test.dart';
import 'package:moi_reporting_app/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MoiReportingApp());
    expect(find.byType(MoiReportingApp), findsOneWidget);
  });
}
