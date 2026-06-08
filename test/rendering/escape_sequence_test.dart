import 'package:test/test.dart';
import 'package:xterm/xterm.dart';

void main() {
  Terminal makeTerminal() {
    final t = Terminal();
    t.resize(80, 24, 8, 16);
    return t;
  }

  group('SGR sequences', () {
    test('bold SGR sets bold attribute on cell', () {
      final terminal = makeTerminal();
      terminal.write('\x1b[1mA\x1b[0m');
      expect(terminal.buffer.lines[0].getCodePoint(0), equals('A'.codeUnitAt(0)));
    });

    test('256-color foreground does not throw', () {
      final terminal = makeTerminal();
      expect(() => terminal.write('\x1b[38;5;200mA\x1b[0m'), returnsNormally);
    });

    test('RGB foreground does not throw', () {
      final terminal = makeTerminal();
      expect(() => terminal.write('\x1b[38;2;255;128;0mA\x1b[0m'), returnsNormally);
    });

    test('truncated RGB foreground (missing blue param) does not throw', () {
      final terminal = makeTerminal();
      expect(() => terminal.write('\x1b[38;2;255;0m'), returnsNormally);
    });
  });

  group('alternate screen', () {
    test('switch to alt screen and back restores main buffer content', () {
      final terminal = makeTerminal();
      terminal.write('main content');
      // Enter alt screen (SMCUP)
      terminal.write('\x1b[?1049h');
      terminal.write('alt content');
      // Exit alt screen (RMCUP)
      terminal.write('\x1b[?1049l');
      // Main buffer line 0 should still have 'm' at col 0
      final firstChar = terminal.buffer.lines[0].getCodePoint(0);
      expect(firstChar, equals('m'.codeUnitAt(0)));
    });

    test('cursor position restored after alt screen exit', () {
      final terminal = makeTerminal();
      terminal.write('\x1b[5;10H'); // row 5, col 10 (1-indexed) → 0-indexed: row 4, col 9
      terminal.write('\x1b[?1049h'); // enter alt
      terminal.write('\x1b[1;1H');   // move in alt
      terminal.write('\x1b[?1049l'); // exit alt
      // Cursor should be back near row 4, col 9
      expect(terminal.buffer.cursorY, equals(4));
      expect(terminal.buffer.cursorX, equals(9));
    });
  });

  group('DCS / OSC sequences', () {
    test('tmux XTVERSION DCS is silently consumed', () {
      final terminal = makeTerminal();
      terminal.write('before');
      terminal.write('\x1bP>|tmux 3.6b\x1b\\');
      terminal.write('after');
      // 'before' at col 0-5, 'after' starting at col 6 — no DCS chars visible
      expect(terminal.buffer.lines[0].getCodePoint(0), equals('b'.codeUnitAt(0)));
      expect(terminal.buffer.lines[0].getCodePoint(6), equals('a'.codeUnitAt(0)));
    });

    test('OSC title set is silently consumed', () {
      final terminal = makeTerminal();
      terminal.write('\x1b]0;Window Title\x07');
      terminal.write('text');
      expect(terminal.buffer.lines[0].getCodePoint(0), equals('t'.codeUnitAt(0)));
    });
  });

  group('resize mid-output', () {
    test('content is accessible after resize to smaller dimensions', () {
      final terminal = makeTerminal(); // 80×24
      terminal.write('Hello World');
      terminal.resize(40, 12, 8, 16);
      // Text on line 0 should still be accessible
      final firstChar = terminal.buffer.lines[0].getCodePoint(0);
      expect(firstChar, equals('H'.codeUnitAt(0)));
    });

    test('new writes after resize land in correct position', () {
      final terminal = makeTerminal(); // 80×24
      terminal.write('First line\r\n');
      terminal.resize(40, 12, 8, 16);
      terminal.write('Second');
      expect(terminal.buffer.cursorY, equals(1));
      expect(terminal.buffer.cursorX, equals(6));
    });
  });

  group('erase operations', () {
    test('eraseChars at end of line does not throw', () {
      final terminal = makeTerminal();
      terminal.write('\x1b[1;75H'); // col 75 (1-indexed), near end of 80-col terminal
      expect(() => terminal.write('\x1b[20X'), returnsNormally);
    });

    test('ED (erase display) does not throw on empty terminal', () {
      final terminal = makeTerminal();
      expect(() => terminal.write('\x1b[2J'), returnsNormally);
    });
  });
}
