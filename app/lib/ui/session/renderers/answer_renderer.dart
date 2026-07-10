import 'package:flutter/widgets.dart';

import '../../../engine/scoring/scoring_engine.dart';

/// Implemented by every auto-graded renderer's [State] so the session screen —
/// or a parent comprehension renderer — can read whether input is ready and
/// pull a score on demand.
abstract class AutoGraded {
  /// True once there is enough input to grade.
  bool get canSubmit;

  /// Scores the current input. Only valid when [canSubmit] is true.
  ScoreResult score();
}

/// Common inputs passed to every renderer.
class RendererArgs {
  final ScoringEngine engine;

  /// Non-null once the answer has been submitted — renderers use it to switch
  /// into read-only feedback mode (highlight right/wrong).
  final ScoreResult? result;

  /// Called whenever [AutoGraded.canSubmit] may have changed, so the parent can
  /// re-enable its "check answer" button.
  final VoidCallback onChanged;

  const RendererArgs({
    required this.engine,
    required this.result,
    required this.onChanged,
  });

  bool get answered => result != null;
}
