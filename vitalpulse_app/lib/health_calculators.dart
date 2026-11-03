import 'dart:math' as math;

class NutritionTargets {
  const NutritionTargets({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  final int calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  NutritionTargets forCalories(int newCalories) {
    final calories = newCalories.clamp(800, 10000);
    final fat = calories * 0.25 / 9;
    final remaining = calories - proteinGrams * 4 - fat * 9;
    return NutritionTargets(
      calories: calories,
      proteinGrams: proteinGrams,
      carbsGrams: math.max(0, remaining / 4),
      fatGrams: fat,
    );
  }
}

int? ageFromBirthYear(int? birthYear, {DateTime? today}) {
  if (birthYear == null) return null;
  final now = today ?? DateTime.now();
  final age = now.year - birthYear;
  if (age < 13 || age > 100) return null;
  return age;
}

NutritionTargets calculateNutritionTargets({
  double? heightCm,
  double? weightKg,
  int? age,
  String gender = 'prefer_not_to_say',
  String goal = 'maintain',
}) {
  final height = (heightCm ?? 170).clamp(120, 230).toDouble();
  final weight = (weightKg ?? 70).clamp(35, 250).toDouble();
  final years = (age ?? 30).clamp(13, 100).toDouble();
  final genderAdjustment = switch (gender) {
    'male' => 5,
    'female' => -161,
    _ => -78,
  };
  final bmr = 10 * weight + 6.25 * height - 5 * years + genderAdjustment;
  final goalAdjustment = switch (goal) {
    'lose' => -300,
    'gain' => 300,
    _ => 0,
  };
  final calories = (bmr * 1.4 + goalAdjustment).round().clamp(1200, 6000);
  final proteinFactor = goal == 'maintain' ? 1.6 : 1.8;
  final protein = weight * proteinFactor;
  final fat = (calories * 0.25 / 9).toDouble();
  final carbs = math.max(0, (calories - protein * 4 - fat * 9) / 4).toDouble();
  return NutritionTargets(
    calories: calories,
    proteinGrams: protein,
    carbsGrams: carbs,
    fatGrams: fat,
  );
}

double progressRatio(num current, num target) {
  if (target <= 0) return 0;
  return (current / target).clamp(0, 1).toDouble();
}

int calculateWellnessScore({
  required num calories,
  required num calorieTarget,
  required num proteinGrams,
  required num proteinTarget,
  required num waterMl,
  required num waterTarget,
  required num sleepHours,
  required num steps,
}) {
  double targetProgress(num current, num target) =>
      progressRatio(current, target);
  double calorieAdherence() {
    if (calorieTarget <= 0) return 0;
    return (1 - ((calories - calorieTarget).abs() / calorieTarget))
        .clamp(0, 1)
        .toDouble();
  }

  final score =
      calorieAdherence() * 30 +
      targetProgress(proteinGrams, proteinTarget) * 20 +
      targetProgress(waterMl, waterTarget) * 20 +
      progressRatio(sleepHours, 8) * 20 +
      progressRatio(steps, 8000) * 10;
  return score.round().clamp(0, 100);
}

String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

int calculateWellnessStreak(
  Iterable<DateTime> qualifyingDates, {
  DateTime? today,
}) {
  final dates = qualifyingDates.map(dateKey).toSet();
  var cursor = today ?? DateTime.now();
  cursor = DateTime(cursor.year, cursor.month, cursor.day);
  var streak = 0;
  while (dates.contains(dateKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}
