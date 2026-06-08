import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

void main() {
  const fixturesDir = 'test/fixtures';

  Terminal makeTerminal() {
    final t = Terminal(maxLines: 100000);
    t.resize(80, 24, 8, 16);
    return t;
  }

  // Auto-discover all .pty files in test/fixtures/ — adding a new file
  // automatically adds a test case without any code change.
  final fixtures = Directory(fixturesDir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.pty'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  group('corpus replay', () {
    for (final fixture in fixtures) {
      final name = fixture.uri.pathSegments.last;

      test('$name: single write does not crash and leaves cursor in bounds', () {
        final terminal = makeTerminal();
        final content = fixture.readAsStringSync();
        expect(() => terminal.write(content), returnsNormally);
        expect(
          terminal.buffer.cursorX,
          inInclusiveRange(0, terminal.viewWidth - 1),
        );
        expect(
          terminal.buffer.cursorY,
          inInclusiveRange(0, terminal.viewHeight - 1),
        );
      });

      test('$name: byte-by-byte write produces same cursor as single write', () {
        final content = fixture.readAsStringSync();

        final single = makeTerminal();
        single.write(content);

        final perByte = makeTerminal();
        for (final char in content.split('')) {
          perByte.write(char);
        }

        expect(perByte.buffer.cursorX, equals(single.buffer.cursorX));
        expect(perByte.buffer.cursorY, equals(single.buffer.cursorY));
      });
    }
  });
}
