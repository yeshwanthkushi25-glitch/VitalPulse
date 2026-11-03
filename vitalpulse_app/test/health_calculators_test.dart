import 'package:flutter_test/flutter_test.dart';
import 'package:vitalpulse/health_calculators.dart';

void main() {
  group('nutrition target calculator', () {
    test('uses height, weight, age, gender, and goal in the estimate', () {
      final targets = calculateNutritionTargets(
        heightCm: 180,
        weightKg: 80,
        age: 30,
        gender: 'male',
        goal: 'maintain',
      );

      expect(targets.calories, 2492);
      expect(targets.proteinGrams, closeTo(128, 0.01));
      expect(targets.fatGrams, closeTo(69.22, 0.01));
      expect(targets.carbsGrams, closeTo(339.25, 0.01));
    });

    test('weight-loss target reduces calories and increases protein ratio', () {
      final maintain = calculateNutritionTargets(
        heightCm: 170,
        weightKg: 70,
        age: 35,
        gender: 'female',
        goal: 'maintain',
      );
      final lose = calculateNutritionTargets(
        heightCm: 170,
        weightKg: 70,
        age: 35,
        gender: 'female',
        goal: 'lose',
      );

      expect(lose.calories, maintain.calories - 300);
      expect(lose.proteinGrams, closeTo(126, 0.01));
    });

    test('custom calories preserve protein and rebalance carbs and fat', () {
      final targets = calculateNutritionTargets(
        heightCm: 175,
        weightKg: 75,
        age: 28,
      ).forCalories(2200);

      expect(targets.calories, 2200);
      expect(targets.fatGrams, closeTo(61.11, 0.01));
      expect(
        targets.proteinGrams * 4 +
            targets.carbsGrams * 4 +
            targets.fatGrams * 9,
        closeTo(2200, 0.01),
      );
    });
  });

  group('wellness calculator', () {
    test('returns 100 when every daily target is met', () {
      expect(
        calculateWellnessScore(
          calories: 2200,
          calorieTarget: 2200,
          proteinGrams: 130,
          proteinTarget: 130,
          waterMl: 2500,
          waterTarget: 2500,
          sleepHours: 8,
          steps: 8000,
        ),
        100,
      );
    });

    test('clamps progress and streak values safely', () {
      expect(progressRatio(150, 100), 1);
      expect(progressRatio(0, 0), 0);
      final today = DateTime(2026, 11, 4);
      expect(
        calculateWellnessStreak([
          today,
          today.subtract(const Duration(days: 1)),
        ], today: today),
        2,
      );
      expect(
        calculateWellnessStreak([
          today.subtract(const Duration(days: 2)),
        ], today: today),
        0,
      );
    });
  });

  test('calculates age from birth year', () {
    expect(ageFromBirthYear(1990, today: DateTime(2026, 11, 4)), 36);
    expect(ageFromBirthYear(2015, today: DateTime(2026, 11, 4)), isNull);
  });
}
