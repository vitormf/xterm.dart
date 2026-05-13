import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/src/ui/custom_text_edit.dart';

/// Pumps a [CustomTextEdit] in the non-deleteDetection path and returns the
/// state plus the inserted-text log so each test can drive the
/// [TextInputClient] surface directly.
Future<
    ({
      CustomTextEditState state,
      List<String> inserts,
      List<void> deletes,
    })> _pump(
  WidgetTester tester,
) async {
  final focusNode = FocusNode();
  addTearDown(focusNode.dispose);
  final key = GlobalKey<CustomTextEditState>();
  final inserts = <String>[];
  final deletes = <void>[];

  await tester.pumpWidget(MaterialApp(
    home: Material(
      child: CustomTextEdit(
        key: key,
        focusNode: focusNode,
        onInsert: inserts.add,
        onDelete: () => deletes.add(null),
        onComposing: (_) {},
        onAction: (_) {},
        onKeyEvent: (_, __) => KeyEventResult.ignored,
        child: const SizedBox(width: 100, height: 100),
      ),
    ),
  ));

  // Trigger _openInputConnection by claiming primary focus.
  focusNode.requestFocus();
  await tester.pump();

  return (state: key.currentState!, inserts: inserts, deletes: deletes);
}

void main() {
  group('CustomTextEdit non-deleteDetection diff', () {
    testWidgets(
      'emits each char as the platform-mirror text grows',
      (tester) async {
        final (:state, :inserts, :deletes) = await _pump(tester);
        state.updateEditingValue(const TextEditingValue(
          text: 'a',
          selection: TextSelection.collapsed(offset: 1),
        ));
        state.updateEditingValue(const TextEditingValue(
          text: 'ab',
          selection: TextSelection.collapsed(offset: 2),
        ));
        state.updateEditingValue(const TextEditingValue(
          text: 'abc',
          selection: TextSelection.collapsed(offset: 3),
        ));
        expect(inserts, ['a', 'b', 'c']);
        expect(deletes, isEmpty);
      },
    );

    testWidgets(
      // Regression: 06ea1ca dropped the per-event "reset platform to
      // _initEditingState" call in the non-deleteDetection branch, so the
      // platform's text field now accumulates instead of being cleared
      // after each insert. On Android (the client uses deleteDetection=false
      // with keyboardType=visiblePassword), the IME sees a non-empty field
      // and intercepts backspace itself — sending a shorter
      // TextEditingValue rather than a hardware DEL key event. Without
      // shrinkage detection, that backspace was silently dropped.
      'emits onDelete when the platform-mirror text shrinks (backspace)',
      (tester) async {
        final (:state, :inserts, :deletes) = await _pump(tester);
        // Prime the mirror.
        state.updateEditingValue(const TextEditingValue(
          text: 'abc',
          selection: TextSelection.collapsed(offset: 3),
        ));
        expect(inserts, ['abc']);
        expect(deletes, isEmpty);

        // IME-intercepted backspace: field shrinks by one char.
        state.updateEditingValue(const TextEditingValue(
          text: 'ab',
          selection: TextSelection.collapsed(offset: 2),
        ));
        expect(deletes.length, 1);

        // Multi-char shrink (e.g. user deletes a word) emits one onDelete
        // per removed character.
        state.updateEditingValue(const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        ));
        expect(deletes.length, 3);
      },
    );

    testWidgets(
      // Regression: the original `_seenText`-mirror patch
      // (06ea1ca) reset only on widget construction, so a close→reopen
      // cycle of the [TextInputConnection] (focus loss + regain) left the
      // mirror carrying the previous session's length. The platform's
      // initial setEditingState reset takes effect on a fresh connection,
      // so the next keystroke arrives as `text: "x"` (length 1) and gets
      // silently dropped against a stale `_seenText` of length 3.
      'first keystroke after focus loss+regain is still emitted',
      (tester) async {
        final (:state, :inserts, :deletes) = await _pump(tester);
        // Prime the mirror with three chars worth of accumulated state.
        state.updateEditingValue(const TextEditingValue(
          text: 'abc',
          selection: TextSelection.collapsed(offset: 3),
        ));
        expect(inserts, ['abc']);
        inserts.clear();

        // Simulate switching away (close) and switching back (reopen).
        state.widget.focusNode.unfocus();
        await tester.pump();
        state.widget.focusNode.requestFocus();
        await tester.pump();

        // First keystroke after reopen — would have been dropped without
        // the fix, because `_seenText` would still be "abc" while the
        // platform's freshly-reset mirror sends `text: "x"` (length 1).
        state.updateEditingValue(const TextEditingValue(
          text: 'x',
          selection: TextSelection.collapsed(offset: 1),
        ));
        expect(inserts, ['x']);
      },
    );
  });
}
