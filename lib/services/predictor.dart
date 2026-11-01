import 'dart:math';

class Predictor {
  static const List<double> _defaultWeights = [180.0, 520.0, 90.0, 0.55];

  List<double> _weights = List.of(_defaultWeights);
  bool _trained = false;
  int _trainingSamples = 0;
  DateTime? _trainedAt;

  List<double> get weights => List.unmodifiable(_weights);
  bool get isTrained => _trained;
  int get trainingSamples => _trainingSamples;
  DateTime? get trainedAt => _trainedAt;

  // Public so ModelTrainer can use them
  static double eveningFeature(int hourOfDay) =>
      exp(-pow(hourOfDay - 19, 2) / 8);

  static double weekdayFeature(int dayOfWeek) => dayOfWeek <= 5 ? 1.0 : 0.0;

  static List<double> featuresFor({
    required int hourOfDay,
    required int dayOfWeek,
    required double avg3hW,
  }) => [eveningFeature(hourOfDay), weekdayFeature(dayOfWeek), avg3hW];

  double predictNextHourW({
    required int hourOfDay,
    required int dayOfWeek,
    required double avg3hW,
  }) {
    final x = featuresFor(
      hourOfDay: hourOfDay,
      dayOfWeek: dayOfWeek,
      avg3hW: avg3hW,
    );
    return _weights[0] +
        _weights[1] * x[0] +
        _weights[2] * x[1] +
        _weights[3] * x[2];
  }

  double baselineNextHourW(double avg3hW) => avg3hW;

  void applyWeights(List<double> w, {required int sampleCount, DateTime? at}) {
    if (w.length != 4) {
      throw ArgumentError('Expected 4 weights, got ${w.length}');
    }
    _weights = List.of(w);
    _trained = true;
    _trainingSamples = sampleCount;
    _trainedAt = at ?? DateTime.now();
  }

  void resetToDefaults() {
    _weights = List.of(_defaultWeights);
    _trained = false;
    _trainingSamples = 0;
    _trainedAt = null;
  }

  Map<String, dynamic> toJson() => {
    'weights': _weights,
    'trained': _trained,
    'samples': _trainingSamples,
    'trainedAt': _trainedAt?.millisecondsSinceEpoch,
  };

  void loadFromJson(Map<String, dynamic> m) {
    final w = List<double>.from(
      (m['weights'] as List).map((e) => (e as num).toDouble()),
    );
    if (w.length == 4) {
      _weights = w;
    }
    _trained = m['trained'] as bool? ?? false;
    _trainingSamples = m['samples'] as int? ?? 0;
    final ts = m['trainedAt'] as int?;
    _trainedAt = ts == null ? null : DateTime.fromMillisecondsSinceEpoch(ts);
  }
}
