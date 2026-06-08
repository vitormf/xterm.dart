import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

void main() {
  group('cursor bounds', () {
    test('restoreCursor clamps X after resize makes saved position out of bounds', () {
      final terminal = Terminal();
      // Start at 80×24
      terminal.resize(80, 24, 8, 16);
      // Move cursor to column 70 (0-indexed: col 69), save it
      terminal.write('\x1b[1;70H'); // row 1, col 70 (1-indexed)
      terminal.write('\x1b7');      // save cursor (DECSC)
      // Resize to 40 cols — saved col 69 is now out of bounds
      terminal.resize(40, 24, 8, 16);
      // Restore cursor — should clamp to col 39 (viewWidth - 1)
      terminal.write('\x1b8');      // restore cursor (DECRC)
      expect(terminal.buffer.cursorX, lessThanOrEqualTo(terminal.viewWidth - 1));
      expect(terminal.buffer.cursorX, greaterThanOrEqualTo(0));
    });

    test('restoreCursor clamps Y after resize makes saved row out of bounds', () {
      final terminal = Terminal();
      terminal.resize(80, 24, 8, 16);
      terminal.write('\x1b[20;1H'); // row 20 (1-indexed)
      terminal.write('\x1b7');       // save
      terminal.resize(80, 10, 8, 16); // shrink to 10 rows
      terminal.write('\x1b8');        // restore — row 19 now out of bounds
      expect(terminal.buffer.cursorY, lessThanOrEqualTo(terminal.viewHeight - 1));
      expect(terminal.buffer.cursorY, greaterThanOrEqualTo(0));
    });

    test('eraseChars does not exceed viewWidth', () {
      final terminal = Terminal();
      terminal.resize(10, 5, 8, 16);
      terminal.write('\x1b[1;8H'); // col 8 (1-indexed), 0-indexed: col 7
      // Erase 10 chars from col 7 — would go to col 17, past viewWidth=10
      expect(() => terminal.write('\x1b[10X'), returnsNormally);
    });
  });
}
