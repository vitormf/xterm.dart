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

  group('DCS (Device Control String)', () {
    // Regression for vitormf/nimue#647.
    // tmux responds to XTVERSION (CSI > q) with "ESC P > | tmux VERSION ESC \".
    // Without DCS handling the raw bytes were passed to the output buffer and
    // rendered literally as "^[P>|tmux...".
    test('ESC P ... ESC \\ is consumed silently, unkownEscape never called', () {
      final handler = MockEscapeHandler();
      final parser = EscapeParser(handler);
      expect(
        () => parser.write('\x1bP>|tmux 3.6b\x1b\\'),
        returnsNormally,
      );
      verifyNever(handler.unkownEscape(any));
    });

    test('DCS terminated by BEL is consumed silently', () {
      final handler = MockEscapeHandler();
      final parser = EscapeParser(handler);
      expect(
        () => parser.write('\x1bPsome data\x07'),
        returnsNormally,
      );
      verifyNever(handler.unkownEscape(any));
    });

    test('DCS split across two writes is fully consumed', () {
      final handler = MockEscapeHandler();
      final parser = EscapeParser(handler);
      parser.write('\x1bP>|tmux');
      parser.write(' 3.6b\x1b\\');
      verifyNever(handler.unkownEscape(any));
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
