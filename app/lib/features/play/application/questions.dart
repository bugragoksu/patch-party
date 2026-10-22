import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pre-generated question pool (FR-08, FR-40). Loaded lazily after joining;
/// keys are "interestA|interestB" (sorted) plus "general".
class QuestionPool {
  const new(this._byKey);

  final Map<String, List<String>> _byKey;

  /// Same key + seed gives both players the same question.
  String questionFor(String key, int seed) {
    final list = _byKey[key];
    final pool = (list == null || list.isEmpty) ? _byKey['general'] : list;
    if (pool == null || pool.isEmpty) return fallback;
    return pool[seed % pool.length];
  }

  static const fallback =
      'Bugün buraya gelmeden önce en son neyle uğraşıyordun?';
}

const questionPoolAsset = 'assets/content/questions.json';

final questionPoolProvider = FutureProvider<QuestionPool>((ref) async {
  final raw = await rootBundle.loadString(questionPoolAsset);
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final pools = (json['pools'] as Map<String, dynamic>).map(
    (k, v) => MapEntry(k, (v as List).cast<String>()),
  );
  return QuestionPool(pools);
});
