import 'dart:math';

import '../models/models.dart';
import 'predictor.dart';

class TrainingSample {
  final double evening; // x1
  final double weekday; // x2
  final double avg3hW; // x3
  final double actualW; // y
  TrainingSample(this.evening, this.weekday, this.avg3hW, this.actualW);
}

class TrainingResult {
  final List<double> weights;
  final int samples;
  final double trainMAE;
  final double baselineMAE;
  final int iterations;
  final double finalLoss;

  TrainingResult({
    required this.weights,
    required this.samples,
    required this.trainMAE,
    required this.baselineMAE,
    required this.iterations,
    required this.finalLoss,
  });
}

/// Fits a 4-parameter linear model to hourly consumption records
/// using batch gradient descent with ridge regularization.
///
/// Model:    ŷ = w0 + w1·evening(hour) + w2·weekday + w3·avg3h
/// Loss:     ½·MSE + (λ/2)·||w[1..3]||²   (bias w0 is not regularized)
/// Algorithm: batch gradient descent, ~600 iterations, small enough to run
///            in <50 ms on a mid-range phone for typical sample counts.
class ModelTrainer {
  ModelTrainer({
    this.learningRate = 0.02,
    this.iterations = 800,
    this.ridgeLambda = 0.05,
    this.minSamples = 24,
  });

  final double learningRate;
  final int iterations;
  final double ridgeLambda;

  /// Below this many samples, retraining is refused — you can't learn
  /// a daily pattern from an hour of data.
  final int minSamples;

  /// Build training samples from a chronological list of Hive records.
  /// Each target is the *next* record's load, feature-computed from the
  /// record that preceded it (mirrors how predictions run live).
  List<TrainingSample> buildSamples(List<ConsumptionRecord> records) {
    if (records.length < 5) return const [];
    final out = <TrainingSample>[];
    // Need 3 hours of history before each target
    for (var i = 4; i < records.length; i++) {
      final prev = records[i - 1];
      final target = records[i];

      // Average of the 3 records before the target
      final a = records[i - 4].loadW;
      final b = records[i - 3].loadW;
      final c = records[i - 2].loadW;
      final avg3h = (a + b + c) / 3;

      out.add(
        TrainingSample(
          Predictor.eveningFeature(prev.time.hour),
          Predictor.weekdayFeature(prev.time.weekday),
          avg3h,
          target.loadW,
        ),
      );
    }
    return out;
  }

  /// Fit weights to [samples]. Returns a [TrainingResult] with diagnostics.
  TrainingResult? fit(List<TrainingSample> samples) {
    if (samples.length < minSamples) return null;

    // Initialize from the shipped defaults for stable convergence.
    var w0 = 180.0, w1 = 520.0, w2 = 90.0, w3 = 0.55;

    // Scale avg3hW so gradient magnitudes are comparable across features.
    final scale3 = _rms(samples.map((s) => s.avg3hW)) / 500.0;
    final invScale3 = scale3 == 0 ? 1.0 : 1.0 / scale3;

    final n = samples.length;
    double loss = 0;

    for (var it = 0; it < iterations; it++) {
      double g0 = 0, g1 = 0, g2 = 0, g3 = 0;
      loss = 0;

      for (final s in samples) {
        final x3 = s.avg3hW * invScale3;
        final yHat = w0 + w1 * s.evening + w2 * s.weekday + w3 * x3;
        final err = yHat - s.actualW;
        loss += err * err;

        g0 += err;
        g1 += err * s.evening;
        g2 += err * s.weekday;
        g3 += err * x3;
      }

      loss = loss / (2 * n) + 0.5 * ridgeLambda * (w1 * w1 + w2 * w2 + w3 * w3);

      // Average gradients + ridge term (except bias)
      g0 /= n;
      g1 = g1 / n + ridgeLambda * w1;
      g2 = g2 / n + ridgeLambda * w2;
      g3 = g3 / n + ridgeLambda * w3;

      w0 -= learningRate * g0;
      w1 -= learningRate * g1;
      w2 -= learningRate * g2;
      w3 -= learningRate * g3;
    }

    // Unscale w3 back to real units
    w3 = w3 * invScale3;

    final weights = [w0, w1, w2, w3];
    final finalTrainMAE = _mae(samples, weights);
    final baselineMAE = _baselineMae(samples);

    return TrainingResult(
      weights: weights,
      samples: samples.length,
      trainMAE: finalTrainMAE,
      baselineMAE: baselineMAE,
      iterations: iterations,
      finalLoss: loss,
    );
  }

  // ---------- Diagnostics ----------

  double _mae(List<TrainingSample> s, List<double> w) {
    double sum = 0;
    for (final t in s) {
      final p = w[0] + w[1] * t.evening + w[2] * t.weekday + w[3] * t.avg3hW;
      sum += (p - t.actualW).abs();
    }
    return sum / s.length;
  }

  double _baselineMae(List<TrainingSample> s) {
    double sum = 0;
    for (final t in s) {
      sum += (t.avg3hW - t.actualW).abs();
    }
    return sum / s.length;
  }

  double _rms(Iterable<double> xs) {
    double acc = 0;
    int n = 0;
    for (final x in xs) {
      acc += x * x;
      n++;
    }
    return n == 0 ? 0 : sqrt(acc / n);
  }
}
