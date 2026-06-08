import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

void main() {
  group('RenderTerminal resize repaint', () {
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
}
