// boundary_search.dart — where does a candidate stop holding?
//
// Complexity is raised along a named axis (variant count, nesting depth, edge
// count, data volume) until the candidate breaks; bisecting finds the last
// level that held with few runs. It assumes holding is monotone in the level:
// if a level holds, every lower one does. [firstNonMonotone] checks that
// assumption instead of trusting it.

/// What a search found.
typedef BoundarySearchResult = ({
  int? highestHolding,
  int? lowestFailing,
  int evaluations,
});

/// Finds the highest of [levels] (ascending, distinct) at which [holds] is true.
/// [BoundarySearchResult.lowestFailing] is null when even the top level holds
/// (the candidate never broke); [BoundarySearchResult.highestHolding] is null
/// when even the bottom level fails.
BoundarySearchResult findBoundary(
  List<int> levels,
  bool Function(int level) holds,
) {
  var evaluations = 0;
  bool check(int index) {
    evaluations++;
    return holds(levels[index]);
  }

  if (levels.isEmpty) {
    return (highestHolding: null, lowestFailing: null, evaluations: 0);
  }
  if (!check(0)) {
    return (highestHolding: null, lowestFailing: levels.first, evaluations: evaluations);
  }
  if (check(levels.length - 1)) {
    return (highestHolding: levels.last, lowestFailing: null, evaluations: evaluations);
  }
  var low = 0;
  var high = levels.length - 1;
  while (high - low > 1) {
    final middle = (low + high) ~/ 2;
    if (check(middle)) {
      low = middle;
    } else {
      high = middle;
    }
  }
  return (
    highestHolding: levels[low],
    lowestFailing: levels[high],
    evaluations: evaluations,
  );
}

/// The first level in [levels] that holds after a lower one failed, or null if
/// holding is monotone over them. Every level is run, so use it to verify the
/// assumption bisecting makes, not on every change.
int? firstNonMonotone(List<int> levels, bool Function(int level) holds) {
  var failed = false;
  for (final level in levels) {
    final held = holds(level);
    if (failed && held) return level;
    if (!held) failed = true;
  }
  return null;
}

/// The fraction of [levels] up to and including [highestHolding]; 0 when none
/// held. This is the boundary factor of the confidence.
double normalizedBoundary(List<int> levels, int? highestHolding) =>
    highestHolding == null || levels.isEmpty
        ? 0
        : (levels.indexOf(highestHolding) + 1) / levels.length;
