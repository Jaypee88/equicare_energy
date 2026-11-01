import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/energy_provider.dart';

class ModelScreen extends StatelessWidget {
  const ModelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<EnergyProvider>();
    final pred = p.predictor;
    final last = p.lastTrainingResult;
    final scheme = Theme.of(context).colorScheme;

    String f(double? v) => v == null ? '—' : '${v.toStringAsFixed(0)} W';
    String mae(double v) => '${v.toStringAsFixed(1)} W';

    return Scaffold(
      appBar: AppBar(title: const Text('Model')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Predicts the next hour\'s load from time-of-day, weekday, '
            'and recent average. Ridge-regularized linear regression, '
            'fit on-device from this installation\'s own history.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          // --- Model status ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        pred.isTrained
                            ? Icons.check_circle
                            : Icons.info_outline,
                        color: pred.isTrained
                            ? Colors.green
                            : scheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        pred.isTrained
                            ? 'Trained on this device'
                            : 'Using shipped defaults',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (pred.isTrained) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Samples: ${pred.trainingSamples}',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    Text(
                      'Trained: ${pred.trainedAt}',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Current weights',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pred.weights.map((w) => w.toStringAsFixed(2)).join('  ·  '),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // --- Live comparison ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live prediction',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _row('Last actual', f(p.lastActualW)),
                  _row('ML prediction', f(p.lastPredictionW)),
                  _row('Baseline (3h avg)', f(p.lastBaselineW)),
                  const Divider(),
                  _row('Rolling ML MAE', mae(p.mlMAE)),
                  _row('Rolling baseline MAE', mae(p.baselineMAE)),
                  _row('Samples', '${p.sampleCount}'),
                ],
              ),
            ),
          ),

          if (last != null) ...[
            const SizedBox(height: 12),
            Card(
              color: successBanner(context).bg,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last retraining result',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _row('Training samples', '${last.samples}'),
                    _row('Train MAE', mae(last.trainMAE)),
                    _row('Baseline MAE', mae(last.baselineMAE)),
                    _row('Iterations', '${last.iterations}'),
                    const SizedBox(height: 8),
                    Text(
                      last.trainMAE < last.baselineMAE
                          ? '✅ Model beats baseline on training data by '
                                '${(last.baselineMAE - last.trainMAE).toStringAsFixed(1)} W.'
                          : '⚠️ Model does not beat baseline yet — need more '
                                'varied history.',
                      style: TextStyle(
                        color: last.trainMAE < last.baselineMAE
                            ? successBanner(context).fg
                            : severityColors(context, Severity.warning).fg,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // --- Actions ---
          FilledButton.icon(
            icon: p.isTraining
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.model_training),
            label: Text(p.isTraining ? 'Training…' : 'Retrain on this device'),
            onPressed: p.isTraining
                ? null
                : () async {
                    final result = await p.retrainModel();
                    if (!context.mounted) return;
                    if (result == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Not enough history yet — collect at least '
                            'an hour of data before retraining.',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Retrained on ${result.samples} samples • '
                            'MAE ${result.trainMAE.toStringAsFixed(1)} W '
                            '(baseline ${result.baselineMAE.toStringAsFixed(1)} W)',
                          ),
                        ),
                      );
                    }
                  },
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: p.isTrained ? p.resetModel : null,
            child: const Text('Reset to shipped defaults'),
          ),

          const SizedBox(height: 24),
          Text(
            'Note: the shipped defaults were fit on simulated data. '
            'Once this installation has run for a few days, tap '
            '"Retrain" — the app fits the model on its own history and '
            'the rolling MAE updates live.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
