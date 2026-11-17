// dependent_pin.dart — which packages depend on dartrix, and whether the commit
// each one pins is the commit dartrix is at.
//
// A pin is how a dependent says which dartrix it was proven against. When dartrix
// changes, every dependent whose pin is behind needs its own PR to bump it, with
// its full suite. No file or process I/O here: the caller reads the pubspec text
// and the commit, so this is testable without a checkout.

/// A package that depends on dartrix through git.
enum Dependent {
  /// The workflow CLI; pins a commit.
  claudart(directoryName: 'claudart'),

  /// The dashboard; today it pins nothing.
  zedup(directoryName: 'zedup');

  const Dependent({required this.directoryName});

  /// The checkout's directory, beside dartrix's own.
  final String directoryName;
}

/// How a dependent's pin stands against dartrix's current commit.
enum PinState {
  /// The pin is the commit dartrix is at: nothing to update.
  current(needsUpdatePr: false),

  /// The pin is another commit: dartrix moved on, the dependent needs a PR.
  behind(needsUpdatePr: true),

  /// No ref at all: pub takes whatever the default branch is at when it
  /// resolves, so the dependent cannot say what it was proven against. It
  /// needs a PR that pins it.
  floating(needsUpdatePr: true);

  const PinState({required this.needsUpdatePr});

  /// Whether the dependent needs a PR.
  final bool needsUpdatePr;
}

/// The `ref:` the git dependency [package] has in [pubspecText], or null when the
/// dependency has none or is not there.
String? pinnedRefIn(String pubspecText, String package) {
  final lines = pubspecText.split('\n');
  final start = lines.indexWhere((l) => l.trimRight() == '  $package:');
  if (start < 0) return null;
  for (var i = start + 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
    if (!line.startsWith('    ')) return null;
    final match = RegExp(r'^\s+ref:\s*(\S+)').firstMatch(line);
    if (match != null) return match.group(1);
  }
  return null;
}

/// The state of a pin at [pinnedRef] when dartrix is at [headRef].
PinState pinStateOf({required String? pinnedRef, required String headRef}) {
  if (pinnedRef == null) return PinState.floating;
  return pinnedRef == headRef ? PinState.current : PinState.behind;
}

/// One dependent's standing, for the report.
typedef DependentStanding = ({
  Dependent dependent,
  String? pinnedRef,
  PinState state,
});

/// What each dependent has to do, written for a PR body: one line for each, in
/// the order of [Dependent.values]. [pubspecTexts] holds the pubspec of every
/// dependent that was found; one that was not found is reported as such.
String renderDependentsReport({
  required String headRef,
  required Map<Dependent, String> pubspecTexts,
}) {
  final buffer = StringBuffer()
    ..writeln('## Dependents to update')
    ..writeln()
    ..writeln('dartrix is at `$headRef`.')
    ..writeln();
  for (final dependent in Dependent.values) {
    final text = pubspecTexts[dependent];
    if (text == null) {
      buffer.writeln('- `${dependent.name}`: checkout not found, check by hand');
      continue;
    }
    final pinned = pinnedRefIn(text, 'dartrix');
    final state = pinStateOf(pinnedRef: pinned, headRef: headRef);
    buffer.writeln('- `${dependent.name}`: ${state.name}'
        '${pinned == null ? '' : ' (pins `$pinned`)'}'
        '${state.needsUpdatePr ? ': open a PR there bumping the pin, '
            'with its full suite' : ''}');
  }
  return buffer.toString();
}

/// The steps a dartrix change goes through before it is pushed, in this order.
/// Each runs in a scratch copy of every dependent, against the local dartrix.
enum VerifyStep {
  /// The dependent's analyzer reports no use of anything dartrix deprecated.
  deprecations,

  /// The dependent still analyzes as it did (no new errors or warnings).
  analyze,

  /// The dependent's full suite passes.
  test,
}

/// How one step ended for one dependent.
enum StepOutcome {
  /// The step ran and passed.
  passed,

  /// The step ran and failed.
  failed,

  /// An earlier step failed, so this one was not run.
  skipped,
}

/// Whether dartrix is ready to push as far as one dependent is concerned: every
/// step passed. A step missing from [outcomes] counts as not passed.
bool readyToPush(Map<VerifyStep, StepOutcome> outcomes) => VerifyStep.values
    .every((step) => outcomes[step] == StepOutcome.passed);

/// The outcome of each step given whether it [passed], in step order: the first
/// failure stops the rest, which are [StepOutcome.skipped].
Map<VerifyStep, StepOutcome> outcomesInOrder(
  Map<VerifyStep, bool> passed,
) {
  final outcomes = <VerifyStep, StepOutcome>{};
  var stopped = false;
  for (final step in VerifyStep.values) {
    if (stopped) {
      outcomes[step] = StepOutcome.skipped;
      continue;
    }
    final ok = passed[step] ?? false;
    outcomes[step] = ok ? StepOutcome.passed : StepOutcome.failed;
    stopped = !ok;
  }
  return outcomes;
}
