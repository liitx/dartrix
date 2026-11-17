// dependent_pin_test.dart — a dependent's pin is read as the spec says and
// classified against dartrix's commit.
//
// Mock data: pubspec texts written to match the three shapes found in the real
// dependents (a pinned ref, a git url with no ref, no dartrix at all).

import 'package:dartrix/dartrix.dart';
import 'package:test/test.dart';

const _pinned = '''
dev_dependencies:
  dartrix:
    git:
      url: https://github.com/liitx/dartrix.git
      # why
      ref: abc123
  custom_lint: ^0.8.1
''';

const _floating = '''
dependencies:
  dartrix:
    git:
      url: https://github.com/liitx/dartrix.git
  http: ^1.6.0
''';

const _refOfAnother = '''
dependencies:
  other:
    git:
      url: https://example.com/other.git
      ref: zzz
  dartrix:
    git:
      url: https://github.com/liitx/dartrix.git
''';

const _floatingBeforeAnother = '''
dependencies:
  dartrix:
    git:
      url: https://github.com/liitx/dartrix.git
  other:
    git:
      url: https://example.com/other.git
      ref: zzz
''';

const _mentionedFirst = '''
# dartrix is pinned below
dependencies:
  dartrix:
    git:
      ref: abc123
''';

const _absent = 'dependencies:\n  http: ^1.6.0\n';

const _pinRows = <({String name, String pubspec, String? ref})>[
  (name: 'a ref after a comment', pubspec: _pinned, ref: 'abc123'),
  (name: 'a git url with no ref', pubspec: _floating, ref: null),
  (name: 'the ref of another package is not its', pubspec: _refOfAnother, ref: null),
  (name: 'the ref of the next package is not its', pubspec: _floatingBeforeAnother, ref: null),
  (name: 'a comment that names it comes first', pubspec: _mentionedFirst, ref: 'abc123'),
  (name: 'no dartrix at all', pubspec: _absent, ref: null),
];

const _stateRows = <({String? pinned, PinState state})>[
  (pinned: 'head', state: PinState.current),
  (pinned: 'old', state: PinState.behind),
  (pinned: null, state: PinState.floating),
];

void main() {
  group('pinnedRefIn', () {
    for (final row in _pinRows) {
      test('${row.name} gives ${row.ref}', () {
        expect(pinnedRefIn(row.pubspec, 'dartrix'), row.ref);
      });
    }
  });

  group('pinStateOf', () {
    for (final row in _stateRows) {
      test('${row.pinned} against head is ${row.state.name}', () {
        expect(pinStateOf(pinnedRef: row.pinned, headRef: 'head'), row.state);
      });
    }

    test('only a pin that is not current needs a PR', () {
      expect(
        PinState.values.where((s) => s.needsUpdatePr),
        [PinState.behind, PinState.floating],
      );
    });
  });

  group('renderDependentsReport', () {
    test('says what each dependent does, and that a missing one is by hand', () {
      expect(
        renderDependentsReport(
          headRef: 'head',
          pubspecTexts: {Dependent.claudart: _pinned.replaceAll('abc123', 'head')},
        ),
        '## Dependents to update\n'
        '\n'
        'dartrix is at `head`.\n'
        '\n'
        '- `claudart`: current (pins `head`)\n'
        '- `zedup`: checkout not found, check by hand\n',
      );
    });

    test('a behind and a floating dependent each need a PR', () {
      final report = renderDependentsReport(
        headRef: 'head',
        pubspecTexts: {Dependent.claudart: _pinned, Dependent.zedup: _floating},
      );
      expect(
        report,
        contains('- `claudart`: behind (pins `abc123`): open a PR there '
            'bumping the pin, with its full suite\n'),
      );
      expect(
        report,
        contains('- `zedup`: floating: open a PR there bumping the pin, '
            'with its full suite\n'),
      );
    });
  });
}
