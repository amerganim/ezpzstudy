/// Levenshtein edit distance between two strings, used to forgive typos and
/// spelling slips in fill-in and grammar-transformation answers.
///
/// Standard two-row dynamic programming, O(a*b) time, O(min(a,b)) space.
int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  // Ensure `a` is the shorter string so the row buffer is as small as possible.
  if (a.length > b.length) {
    final tmp = a;
    a = b;
    b = tmp;
  }

  final aUnits = a.codeUnits;
  final bUnits = b.codeUnits;

  var previous = List<int>.generate(aUnits.length + 1, (i) => i);
  var current = List<int>.filled(aUnits.length + 1, 0);

  for (var j = 1; j <= bUnits.length; j++) {
    current[0] = j;
    for (var i = 1; i <= aUnits.length; i++) {
      final cost = aUnits[i - 1] == bUnits[j - 1] ? 0 : 1;
      final deletion = previous[i] + 1;
      final insertion = current[i - 1] + 1;
      final substitution = previous[i - 1] + cost;
      current[i] = deletion < insertion
          ? (deletion < substitution ? deletion : substitution)
          : (insertion < substitution ? insertion : substitution);
    }
    final swap = previous;
    previous = current;
    current = swap;
  }

  return previous[aUnits.length];
}
