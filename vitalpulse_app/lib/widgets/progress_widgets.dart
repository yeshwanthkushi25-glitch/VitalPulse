import 'package:flutter/material.dart';

class MacroProgressBar extends StatelessWidget {
  const MacroProgressBar({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    this.color,
  });

  final String label;
  final double current;
  final double target;
  final String unit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ratio = target <= 0 ? 0.0 : (current / target).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${current.toStringAsFixed(current < 10 ? 1 : 0)} / ${target.toStringAsFixed(target < 10 ? 1 : 0)} $unit',
              ),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}

class WellnessScoreCard extends StatelessWidget {
  const WellnessScoreCard({
    super.key,
    required this.score,
    required this.streak,
  });

  final int score;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeScore = score.clamp(0, 100);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: safeScore / 100,
                    strokeWidth: 9,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: theme.colorScheme.primary,
                  ),
                  Text(
                    '$safeScore',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily wellness score',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    streak == 0
                        ? 'Log meals and habits to start your streak.'
                        : '$streak-day consistency streak',
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Based on calories, macros, hydration, sleep, and steps.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
