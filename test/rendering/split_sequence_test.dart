import 'package:test/test.dart';
import 'package:xterm/xterm.dart';

void main() {
  group('split escape sequences', () {
    Terminal makeTerminal() {
      final t = Terminal();
      t.resize(80, 24, 8, 16);
      return t;
    }

    test('CSI sequence split across two writes produces same result as one write', () {
      final single = makeTerminal();
      single.write('\x1b[31mHello\x1b[0m');

      final split = makeTerminal();
      split.write('\x1b[31');
      split.write('mHello\x1b[0m');

      expect(split.buffer.cursorX, equals(single.buffer.cursorX));
      // Both terminals should have 'H' at col 0
      final singleCell = single.buffer.lines[0].getCodePoint(0);
      final splitCell = split.buffer.lines[0].getCodePoint(0);
      expect(splitCell, equals(singleCell));
    });

    test('DCS sequence split mid-body is fully consumed', () {
      final terminal = makeTerminal();
      terminal.write('\x1bP>|tmux');
      terminal.write(' 3.6b\x1b\\');
      terminal.write('visible');
      // Only 'visible' should appear; cursor at col 7
      expect(terminal.buffer.cursorX, equals(7));
      expect(terminal.buffer.lines[0].getCodePoint(0), equals('v'.codeUnitAt(0)));
    });

    test('OSC sequence split across writes does not render literally', () {
      final terminal = makeTerminal();
      // OSC 0 ; title BEL — sets window title, should not render
      terminal.write('\x1b]0;My');
      terminal.write(' Title\x07');
      terminal.write('text');
      // 'text' at col 0, not OSC garbage
      expect(terminal.buffer.lines[0].getCodePoint(0), equals('t'.codeUnitAt(0)));
    });

    test('rapid single-char writes produce same buffer as one write', () {
      final single = makeTerminal();
      const content = 'Hello, World!';
      single.write(content);

      final perChar = makeTerminal();
      for (final ch in content.split('')) {
        perChar.write(ch);
      }

      for (int i = 0; i < content.length; i++) {
        expect(
          perChar.buffer.lines[0].getCodePoint(i),
          equals(single.buffer.lines[0].getCodePoint(i)),
          reason: 'Mismatch at col $i',
        );
      }
    });
  });
}
