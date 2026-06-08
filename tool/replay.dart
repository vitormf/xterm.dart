import 'dart:io';
import 'package:xterm/src/terminal.dart';

void main(List<String> args) {
  if (args.isEmpty || args.contains('--help')) {
    print('Usage: flutter dart tool/replay.dart <file.pty> [--split-bytes]');
    print('');
    print(
        '  --split-bytes  Feed file one byte at a time (stress-tests split-sequence handling)');
    exit(args.isEmpty ? 1 : 0);
  }

  final path = args.first;
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('File not found: $path');
    exit(1);
  }

  final splitBytes = args.contains('--split-bytes');
  final content = file.readAsStringSync();

  final terminal = Terminal(maxLines: 100000);
  terminal.resize(80, 24, 8, 16);

  if (splitBytes) {
    for (final char in content.split('')) {
      terminal.write(char);
    }
  } else {
    terminal.write(content);
  }

  print('=== Replay complete ===');
  print('File: $path (${content.length} chars)');
  print('Mode: ${splitBytes ? "byte-by-byte" : "single write"}');
  print('');
  print('Terminal state:');
  print('  Size:   ${terminal.viewWidth}×${terminal.viewHeight}');
  print(
      '  Cursor: col=${terminal.buffer.cursorX} row=${terminal.buffer.cursorY}');
  print('  Lines in buffer: ${terminal.buffer.lines.length}');
}
