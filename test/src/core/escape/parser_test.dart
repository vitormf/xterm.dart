import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:xterm/xterm.dart';

@GenerateNiceMocks([MockSpec<EscapeHandler>()])
import 'parser_test.mocks.dart';

void main() {
  group('EscapeParser', () {
    test('can parse window manipulation', () {
      final parser = EscapeParser(MockEscapeHandler());
      parser.write('\x1b[8;24;80t');
      verify(parser.handler.resize(80, 24));
    });
  });

  group('SGR bounds check', () {
    test('truncated RGB foreground (ESC[38;2;R;Gm — missing blue) does not throw', () {
      final parser = EscapeParser(MockEscapeHandler());
      expect(() => parser.write('\x1b[38;2;255;0m'), returnsNormally);
    });

    test('truncated RGB background (ESC[48;2;R;Gm — missing blue) does not throw', () {
      final parser = EscapeParser(MockEscapeHandler());
      expect(() => parser.write('\x1b[48;2;255;0m'), returnsNormally);
    });

    test('bare ESC[38m (no subparams) does not throw', () {
      final parser = EscapeParser(MockEscapeHandler());
      expect(() => parser.write('\x1b[38m'), returnsNormally);
    });
  });
}
