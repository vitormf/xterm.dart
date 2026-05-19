import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

void main() {
  group('TerminalView enableSelectionGestures', () {
    testWidgets('drag selects when enableSelectionGestures is true (default)', (tester) async {
      final terminal = Terminal();
      terminal.write('Hello World\r\n');
      final controller = TerminalController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TerminalView(
            terminal,
            controller: controller,
          ),
        ),
      ));
      await tester.pump();

      final center = tester.getCenter(find.byType(TerminalView));
      final gesture = await tester.startGesture(center, kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(controller.selection, isNotNull);
    });

    testWidgets('drag does NOT select when enableSelectionGestures is false', (tester) async {
      final terminal = Terminal();
      terminal.write('Hello World\r\n');
      final controller = TerminalController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TerminalView(
            terminal,
            controller: controller,
            enableSelectionGestures: false,
          ),
        ),
      ));
      await tester.pump();

      final center = tester.getCenter(find.byType(TerminalView));
      final gesture = await tester.startGesture(center, kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(controller.selection, isNull);
    });
  });
}
