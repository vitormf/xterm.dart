import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

void main() {
  group('Terminal resize state', () {
    test('terminal viewWidth updates after explicit resize', () {
      final terminal = Terminal();
      terminal.resize(80, 24, 8, 16);
      terminal.write('Hello World');
      expect(terminal.viewWidth, equals(80));

      terminal.resize(40, 24, 8, 16);
      expect(terminal.viewWidth, equals(40));
    });

    test('content written after resize lands at correct column bounds', () {
      final terminal = Terminal();
      terminal.resize(80, 24, 8, 16);
      terminal.write('First\r\n');
      terminal.resize(40, 24, 8, 16);
      terminal.write('Second');
      expect(terminal.buffer.cursorX, lessThanOrEqualTo(39));
      expect(terminal.buffer.cursorX, greaterThanOrEqualTo(0));
    });
  });

  group('RenderTerminal resize repaint', () {
    testWidgets('RenderTerminal.viewWidth updates after widget size change',
        (tester) async {
      final terminal = Terminal();
      terminal.write('Hello World');

      // Set a known test surface size first: 800×400
      await tester.binding.setSurfaceSize(const Size(800, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: TerminalView(terminal, padding: EdgeInsets.zero),
        ),
      );
      await tester.pump();
      final initialCols = terminal.viewWidth;
      expect(initialCols, greaterThan(0));

      // Shrink the test surface to 400×400 — should halve the column count
      await tester.binding.setSurfaceSize(const Size(400, 400));
      await tester.pump();

      // viewWidth must reflect the new smaller constraint
      expect(terminal.viewWidth, lessThan(initialCols));
      expect(terminal.viewWidth, greaterThan(0));
    });
  });
}
