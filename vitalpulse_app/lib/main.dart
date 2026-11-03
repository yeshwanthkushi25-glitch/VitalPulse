import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Publishable client settings are designed to be present in browser builds.
// Authorization remains enforced by Supabase Auth and row-level security.
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://jmteswvfobeqcapykswv.supabase.co',
);
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_ZxRueOA3D9sAT4rv6nLDuA_GivQ2zuz',
);
const legacySupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
final supabaseClientKey = supabasePublishableKey.isNotEmpty
    ? supabasePublishableKey
    : legacySupabaseAnonKey;
final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isNotEmpty && supabaseClientKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseClientKey,
    );
  }
  runApp(const VitalPulseApp());
}

class VitalPulseApp extends StatelessWidget {
  const VitalPulseApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'VitalPulse',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff0ba787),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xfff5f8f7),
      fontFamily: 'Roboto',
    ),
    home: supabaseUrl.isEmpty || supabaseClientKey.isEmpty
        ? const SetupScreen()
        : const AuthGate(),
  );
}

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.monitor_heart,
                  color: Color(0xff0ba787),
                  size: 42,
                ),
                const SizedBox(height: 16),
                Text(
                  'Connect your Supabase project',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Run the database migration, then start this app with SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY provided as Dart compile-time values. Never use a service-role key in the app.',
                ),
                const SizedBox(height: 18),
                const SelectableText('See README.md for setup instructions.'),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: supabase.auth.onAuthStateChange,
    builder: (context, snapshot) => supabase.auth.currentSession == null
        ? const AuthScreen()
        : const DashboardScreen(),
  );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController();
  bool registering = false, busy = false, obscure = true;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final address = email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(address)) {
      setState(() => error = 'Enter a valid email address.');
      return;
    }
    if (password.text.length < 8) {
      setState(() => error = 'Use a password with at least 8 characters.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (registering) {
        final response = await supabase.auth.signUp(
          email: address,
          password: password.text,
          data: {'name': name.text.trim()},
        );
        if (response.session == null && mounted) {
          setState(
            () => error =
                'Check your email to confirm your account, then sign in.',
          );
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: address,
          password: password.text,
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              error = 'Could not connect. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.monitor_heart,
                      color: Color(0xff0ba787),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'VitalPulse',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Small steps. Stronger wellbeing.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    if (registering) ...[
                      TextField(
                        controller: name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Your name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: password,
                      obscureText: obscure,
                      autofillHints: [
                        registering
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => obscure = !obscure),
                          icon: Icon(
                            obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: busy ? null : submit,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          busy
                              ? 'Please wait…'
                              : registering
                              ? 'Create account'
                              : 'Sign in',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                              registering = !registering;
                              error = null;
                            }),
                      child: Text(
                        registering
                            ? 'Already have an account? Sign in'
                            : 'New to VitalPulse? Create an account',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _health = Health();
  final _imagePicker = ImagePicker();
  final name = TextEditingController(),
      height = TextEditingController(),
      weight = TextEditingController(),
      birthYear = TextEditingController(),
      calorieGoal = TextEditingController(),
      waterGoal = TextEditingController();
  final steps = TextEditingController(text: '0'),
      water = TextEditingController(text: '0'),
      sleep = TextEditingController(text: '0'),
      heartRate = TextEditingController(text: '');
  List<Map<String, dynamic>> meals = [];
  List<Map<String, dynamic>> healthHistory = [];
  List<Map<String, dynamic>> nutritionHistory = [];
  String fitnessGoal = 'maintain';
  String gender = 'prefer_not_to_say';
  int sleepCycles = 5;
  TimeOfDay wakeTime = const TimeOfDay(hour: 6, minute: 30);
  bool loading = true, scanning = false, syncingHealth = false;
  String? message;
  String get date => DateTime.now().toIso8601String().substring(0, 10);
  bool get healthSyncSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  int get totalCalories =>
      meals.fold(0, (v, m) => v + ((m['calories_kcal'] as num?)?.round() ?? 0));
  double get totalProtein =>
      meals.fold(0, (v, m) => v + ((m['protein_g'] as num?)?.toDouble() ?? 0));
  double get totalCarbs =>
      meals.fold(0, (v, m) => v + ((m['carbs_g'] as num?)?.toDouble() ?? 0));
  double get totalFats =>
      meals.fold(0, (v, m) => v + ((m['fats_g'] as num?)?.toDouble() ?? 0));
  double get recommendedWaterMl =>
      double.tryParse(waterGoal.text) ??
      ((double.tryParse(weight.text) ?? 70) * 35).clamp(1500, 5000).toDouble();
  int get recommendedCalories {
    final base = ((double.tryParse(weight.text) ?? 65) * 30).round();
    final estimate = fitnessGoal == 'lose'
        ? base - 300
        : fitnessGoal == 'gain'
        ? base + 300
        : base;
    return int.tryParse(calorieGoal.text) ?? estimate;
  }

  String get recommendedBedtime {
    final wake = DateTime(2000, 1, 1, wakeTime.hour, wakeTime.minute);
    final bedtime = wake.subtract(Duration(minutes: sleepCycles * 90 + 15));
    return TimeOfDay.fromDateTime(bedtime).format(context);
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    name.dispose();
    height.dispose();
    weight.dispose();
    birthYear.dispose();
    calorieGoal.dispose();
    waterGoal.dispose();
    steps.dispose();
    water.dispose();
    sleep.dispose();
    heartRate.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final user = supabase.auth.currentUser!;
      final profile = await supabase
          .from('profiles')
          .select(
            'display_name,height_cm,weight_kg,birth_year,fitness_goal,gender,calorie_target_kcal,water_goal_ml,sleep_cycle_target,target_wake_time',
          )
          .eq('id', user.id)
          .maybeSingle();
      final logs = await supabase
          .from('nutrition_logs')
          .select('id,title,calories_kcal,protein_g,entry_type,logged_at')
          .gte('logged_at', '${date}T00:00:00')
          .order('logged_at', ascending: false);
      final health = await supabase
          .from('daily_health_logs')
          .select('steps,heart_rate_bpm,water_ml,sleep_hours')
          .eq('log_date', date)
          .maybeSingle();
      final history = await supabase
          .from('daily_health_logs')
          .select('log_date,steps,heart_rate_bpm,water_ml,sleep_hours')
          .gte(
            'log_date',
            DateTime.now()
                .subtract(const Duration(days: 6))
                .toIso8601String()
                .substring(0, 10),
          )
          .order('log_date', ascending: false);
      final nutritionTrend = await supabase
          .from('nutrition_logs')
          .select('logged_at,calories_kcal')
          .gte(
            'logged_at',
            DateTime.now()
                .subtract(const Duration(days: 6))
                .toIso8601String()
                .substring(0, 10),
          )
          .order('logged_at', ascending: false);
      if (!mounted) return;
      name.text = (profile?['display_name'] as String?)?.isNotEmpty == true
          ? profile!['display_name'] as String
          : user.email?.split('@').first ?? 'friend';
      meals = List<Map<String, dynamic>>.from(logs);
      healthHistory = List<Map<String, dynamic>>.from(history);
      nutritionHistory = List<Map<String, dynamic>>.from(nutritionTrend);
      height.text = '${profile?['height_cm'] ?? ''}';
      weight.text = '${profile?['weight_kg'] ?? ''}';
      birthYear.text = '${profile?['birth_year'] ?? ''}';
      fitnessGoal = (profile?['fitness_goal'] as String?) ?? 'maintain';
      gender = (profile?['gender'] as String?) ?? 'prefer_not_to_say';
      calorieGoal.text = '${profile?['calorie_target_kcal'] ?? ''}';
      waterGoal.text = '${profile?['water_goal_ml'] ?? ''}';
      sleepCycles = (profile?['sleep_cycle_target'] as num?)?.toInt() ?? 5;
      final wake = profile?['target_wake_time'] as String?;
      if (wake != null && RegExp(r'^\d{2}:\d{2}').hasMatch(wake)) {
        wakeTime = TimeOfDay(
          hour: int.parse(wake.substring(0, 2)),
          minute: int.parse(wake.substring(3, 5)),
        );
      }
      if (health != null) {
        steps.text = '${health['steps']}';
        heartRate.text = '${health['heart_rate_bpm'] ?? ''}';
        water.text = '${health['water_ml']}';
        sleep.text = '${health['sleep_hours']}';
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Could not load your health data. Check the Supabase migration and connection.',
        );
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> saveMetrics() async {
    try {
      await supabase.from('daily_health_logs').upsert({
        'log_date': date,
        'steps': int.tryParse(steps.text) ?? 0,
        'heart_rate_bpm': int.tryParse(heartRate.text),
        'water_ml': int.tryParse(water.text) ?? 0,
        'sleep_hours': double.tryParse(sleep.text) ?? 0,
      }, onConflict: 'user_id,log_date');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Today’s metrics saved')));
        await load();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save metrics. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> quickWater(int changeMl) async {
    final current = int.tryParse(water.text) ?? 0;
    water.text = (current + changeMl).clamp(0, 30000).toString();
    await saveMetrics();
  }

  Future<void> saveProfile() async {
    try {
      await supabase
          .from('profiles')
          .update({
            'display_name': name.text.trim(),
            'height_cm': double.tryParse(height.text),
            'weight_kg': double.tryParse(weight.text),
            'birth_year': int.tryParse(birthYear.text),
            'fitness_goal': fitnessGoal,
            'gender': gender,
            'calorie_target_kcal': int.tryParse(calorieGoal.text),
            'water_goal_ml': int.tryParse(waterGoal.text),
            'sleep_cycle_target': sleepCycles,
            'target_wake_time':
                '${wakeTime.hour.toString().padLeft(2, '0')}:${wakeTime.minute.toString().padLeft(2, '0')}:00',
          })
          .eq('id', supabase.auth.currentUser!.id);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile and daily targets updated')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your profile. Try again.'),
          ),
        );
      }
    }
  }

  Future<void> exportBackup() async {
    try {
      final allMeals = await supabase
          .from('nutrition_logs')
          .select(
            'title,entry_type,meal_type,logged_at,portion_g,volume_ml,calories_kcal,protein_g,carbs_g,fats_g,nutrients',
          )
          .order('logged_at', ascending: false)
          .limit(1000);
      final allHealth = await supabase
          .from('daily_health_logs')
          .select('log_date,steps,heart_rate_bpm,sleep_hours,water_ml')
          .order('log_date', ascending: false)
          .limit(365);
      final data = {
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'profile': {
          'display_name': name.text,
          'height_cm': double.tryParse(height.text),
          'weight_kg': double.tryParse(weight.text),
          'birth_year': int.tryParse(birthYear.text),
          'fitness_goal': fitnessGoal,
          'gender': gender,
          'calorie_target_kcal': recommendedCalories,
          'water_goal_ml': recommendedWaterMl.round(),
          'sleep_cycle_target': sleepCycles,
          'target_wake_time':
              '${wakeTime.hour.toString().padLeft(2, '0')}:${wakeTime.minute.toString().padLeft(2, '0')}',
        },
        'nutrition_logs': allMeals,
        'daily_health_logs': allHealth,
      };
      await Clipboard.setData(
        ClipboardData(text: const JsonEncoder.withIndent('  ').convert(data)),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JSON backup copied to clipboard')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not export your backup. Try again.'),
          ),
        );
      }
    }
  }

  Widget profileCard() => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personalized daily blueprint',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Optional body details help estimate a starting calorie and hydration target. These are general estimates.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 170,
                child: TextField(
                  controller: height,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'prefer_not_to_say',
                      child: Text('Prefer not to say'),
                    ),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(
                      value: 'non_binary',
                      child: Text('Non-binary'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => gender = value ?? gender),
                ),
              ),
              SizedBox(
                width: 170,
                child: TextField(
                  controller: weight,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 170,
                child: TextField(
                  controller: birthYear,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Birth year',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: fitnessGoal,
                  decoration: const InputDecoration(
                    labelText: 'Goal',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'lose',
                      child: Text('Weight management'),
                    ),
                    DropdownMenuItem(
                      value: 'maintain',
                      child: Text('Maintain wellbeing'),
                    ),
                    DropdownMenuItem(
                      value: 'gain',
                      child: Text('Build strength'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => fitnessGoal = value ?? 'maintain'),
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: calorieGoal,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calories / day',
                    hintText: 'Auto estimate',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: waterGoal,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Water goal (ml)',
                    hintText: 'Auto estimate',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Estimated starting goals: about $recommendedCalories kcal and ${recommendedWaterMl.round()} ml water per day.',
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: saveProfile,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save profile'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget hydrationCard() => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hydration & beverages',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '${water.text} ml of ${recommendedWaterMl.round()} ml daily water target',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amount in [150, 250, 500])
                OutlinedButton.icon(
                  onPressed: () => quickWater(amount),
                  icon: const Icon(Icons.water_drop_outlined),
                  label: Text('+$amount ml'),
                ),
              OutlinedButton.icon(
                onPressed: () => quickWater(-200),
                icon: const Icon(Icons.remove),
                label: const Text('−200 ml'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final value = TextEditingController();
                  final amount = await showDialog<int>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Add custom water'),
                      content: TextField(
                        controller: value,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Millilitres',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, int.tryParse(value.text)),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  );
                  value.dispose();
                  if (amount != null && amount > 0) await quickWater(amount);
                },
                icon: const Icon(Icons.add),
                label: const Text('Custom amount'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Use “Log food or drink” to record beverages such as coffee, juice, or soda with nutrition details.',
          ),
        ],
      ),
    ),
  );

  Widget sleepCoachCard() => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sleep schedule coach',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Choose a wake time and a 90-minute sleep-cycle estimate.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cycles in [4, 5, 6])
                ChoiceChip(
                  label: Text(
                    '$cycles cycles · ${(cycles * 1.5).toStringAsFixed(1)} h',
                  ),
                  selected: sleepCycles == cycles,
                  onSelected: (_) => setState(() => sleepCycles = cycles),
                ),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await showTimePicker(
                    context: context,
                    initialTime: wakeTime,
                  );
                  if (selected != null) setState(() => wakeTime = selected);
                },
                icon: const Icon(Icons.alarm),
                label: Text('Wake ${wakeTime.format(context)}'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Estimated bedtime: $recommendedBedtime, allowing about 15 minutes to fall asleep. This is a planning estimate, not a medical recommendation.',
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: saveProfile,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Save sleep preferences'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget weeklyCalorieTrend() {
    final totals = <String, int>{};
    for (final entry in nutritionHistory) {
      final timestamp = DateTime.tryParse('${entry['logged_at']}');
      if (timestamp == null) continue;
      final key = timestamp.toLocal().toIso8601String().substring(0, 10);
      totals[key] =
          (totals[key] ?? 0) + ((entry['calories_kcal'] as num?)?.round() ?? 0);
    }
    final days = List.generate(
      7,
      (index) => DateTime.now().subtract(Duration(days: 6 - index)),
    );
    final values = days
        .map((day) => totals[day.toIso8601String().substring(0, 10)] ?? 0)
        .toList();
    final maxCalories = values.fold<int>(1, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 126,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < days.length; index++)
            Expanded(
              child: Tooltip(
                message: '${values[index]} kcal',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            height: (82 * values[index] / maxCalories)
                                .clamp(4, 82)
                                .toDouble(),
                            decoration: BoxDecoration(
                              color: const Color(0xff0ba787),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        days[index].toIso8601String().substring(5, 10),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget historyCard() => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Daily health history',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: exportBackup,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Copy JSON backup'),
              ),
            ],
          ),
          const Text('Seven-day calorie trend'),
          weeklyCalorieTrend(),
          if (healthHistory.isEmpty)
            const Text('Your saved daily health records will appear here.'),
          for (final day in healthHistory)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text('${day['log_date']}'),
              subtitle: Text(
                '${day['steps']} steps · ${day['water_ml']} ml water · ${day['sleep_hours'] ?? 0} h sleep · ${day['heart_rate_bpm'] ?? '—'} bpm',
              ),
            ),
        ],
      ),
    ),
  );

  Future<void> syncDeviceHealth() async {
    if (!healthSyncSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Health Connect sync is available in the Android and iOS apps.',
          ),
        ),
      );
      return;
    }
    setState(() => syncingHealth = true);
    try {
      await _health.configure();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final activityAccess = await Permission.activityRecognition.request();
        if (!activityAccess.isGranted) {
          throw StateError('Step access permission was not granted.');
        }
      }
      const types = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.SLEEP_ASLEEP,
      ];
      final allowed = await _health.requestAuthorization(types);
      if (!allowed) throw StateError('Health data permission was not granted.');
      final now = DateTime.now();
      final start = now.subtract(const Duration(hours: 24));
      final points = await _health.getHealthDataFromTypes(
        types: types,
        startTime: start,
        endTime: now,
      );
      final midnight = DateTime(now.year, now.month, now.day);
      final todaySteps = points
          .where(
            (p) => p.type == HealthDataType.STEPS && p.dateTo.isAfter(midnight),
          )
          .fold<double>(
            0,
            (sum, p) =>
                sum +
                (p.value is NumericHealthValue
                    ? (p.value as NumericHealthValue).numericValue
                    : 0),
          );
      final heartReadings = points
          .where((p) => p.type == HealthDataType.HEART_RATE)
          .map((p) => p.value)
          .whereType<NumericHealthValue>()
          .map((v) => v.numericValue)
          .toList();
      final asleep = points
          .where((p) => p.type == HealthDataType.SLEEP_ASLEEP)
          .fold<int>(
            0,
            (sum, p) =>
                sum +
                p.dateTo.difference(p.dateFrom).inMinutes.clamp(0, 24 * 60),
          );
      if (todaySteps > 0) steps.text = todaySteps.round().toString();
      if (heartReadings.isNotEmpty) {
        heartRate.text =
            (heartReadings.reduce((a, b) => a + b) / heartReadings.length)
                .round()
                .toString();
      }
      if (asleep > 0) sleep.text = (asleep / 60).toStringAsFixed(1);
      await saveMetrics();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not sync health data. Check Health Connect or Apple Health and your permissions.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => syncingHealth = false);
    }
  }

  Future<void> scanMealPhoto() async {
    final scanAsBeverage = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.restaurant_outlined),
              title: const Text('Scan food'),
              onTap: () => Navigator.pop(context, false),
            ),
            ListTile(
              leading: const Icon(Icons.local_drink_outlined),
              title: const Text('Scan a beverage'),
              onTap: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
    if (!mounted || scanAsBeverage == null) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (!kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS))
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose a photo'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final photo = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 75,
        requestFullMetadata: false,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        throw StateError('Choose a photo smaller than 5 MB.');
      }
      final mime =
          photo.mimeType == 'image/png' || photo.mimeType == 'image/webp'
          ? photo.mimeType!
          : 'image/jpeg';
      setState(() {
        scanning = true;
        message = null;
      });
      final response = await supabase.functions.invoke(
        'analyze-food',
        body: {'image_base64': base64Encode(bytes), 'mime_type': mime},
      );
      final result = Map<String, dynamic>.from(response.data as Map);
      final title = (result['title'] as String? ?? '').trim();
      final calories = result['calories_kcal'] as num?;
      final protein = result['protein_g'] as num?;
      final carbs = result['carbs_g'] as num?;
      final fats = result['fats_g'] as num?;
      final portion = result['portion_g'] as num?;
      final confidence = result['confidence_percent'] as num?;
      final nutrients = Map<String, dynamic>.from(
        result['nutrients'] as Map? ?? const {},
      );
      final ingredients = (result['ingredients'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      if (title.isEmpty ||
          calories == null ||
          protein == null ||
          carbs == null ||
          fats == null) {
        throw const FormatException('The nutrition estimate was incomplete.');
      }
      if (!mounted) return;
      final save = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Review nutrition estimate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                '${calories.round()} kcal  •  ${protein.toStringAsFixed(1)} g protein\n${carbs.toStringAsFixed(1)} g carbs  •  ${fats.toStringAsFixed(1)} g fat',
              ),
              if ((portion?.round() ?? 0) > 0)
                Text('Estimated portion: ${portion!.round()} g'),
              if (confidence != null)
                Text('Estimate confidence: ${confidence.round()}%'),
              if (nutrients.isNotEmpty)
                Text(
                  'Sugar ${nutrients['sugar_g'] ?? 0} g · Fiber ${nutrients['fiber_g'] ?? 0} g · Sodium ${nutrients['sodium_mg'] ?? 0} mg',
                ),
              if (ingredients.isNotEmpty)
                Text(
                  'Detected ingredients: ${ingredients.map((row) => row['name']).join(', ')}',
                ),
              const SizedBox(height: 12),
              const Text(
                'AI estimates can be inaccurate. Review the values before saving. Your photo is sent to the configured AI provider and is not saved to VitalPulse.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save meal'),
            ),
          ],
        ),
      );
      if (save == true) {
        await supabase.from('nutrition_logs').insert({
          'entry_type': scanAsBeverage ? 'beverage' : 'food',
          'title': title,
          'meal_type': scanAsBeverage ? 'Drink' : 'Meal',
          if (portion != null && portion > 0) 'portion_g': portion,
          'calories_kcal': calories,
          'protein_g': protein,
          'carbs_g': carbs,
          'fats_g': fats,
          'nutrients': {
            ...nutrients,
            'confidence_percent': confidence,
            'ingredients': ingredients,
          },
          'estimate_source': 'ai_vision',
        });
        await load();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Meal scan failed. Check the AI function setup and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => scanning = false);
    }
  }

  Future<void> addMeal() async {
    final title = TextEditingController(),
        calories = TextEditingController(),
        protein = TextEditingController(),
        carbs = TextEditingController(text: '0'),
        fats = TextEditingController(text: '0'),
        sugar = TextEditingController(text: '0'),
        fiber = TextEditingController(text: '0'),
        portion = TextEditingController(),
        volume = TextEditingController();
    final form = GlobalKey<FormState>();
    var entryType = 'food';
    var mealType = 'Lunch';
    final values = await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Log food or drink'),
          content: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: entryType,
                  decoration: const InputDecoration(labelText: 'Entry type'),
                  items: const [
                    DropdownMenuItem(value: 'food', child: Text('Food')),
                    DropdownMenuItem(value: 'beverage', child: Text('Drink')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => entryType = value ?? 'food'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: mealType,
                  decoration: const InputDecoration(labelText: 'Meal time'),
                  items:
                      const ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Drink']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                  onChanged: (value) =>
                      setDialogState(() => mealType = value ?? 'Lunch'),
                ),
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a name' : null,
                ),
                TextFormField(
                  controller: calories,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calories (kcal)',
                  ),
                  validator: (v) => (int.tryParse(v ?? '') ?? -1) < 0
                      ? 'Enter zero or more'
                      : null,
                ),
                TextFormField(
                  controller: protein,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Protein (g)'),
                  validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0
                      ? 'Enter zero or more'
                      : null,
                ),
                TextFormField(
                  controller: carbs,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Carbohydrates (g)',
                  ),
                  validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0
                      ? 'Enter zero or more'
                      : null,
                ),
                TextFormField(
                  controller: fats,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Fat (g)'),
                  validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0
                      ? 'Enter zero or more'
                      : null,
                ),
                TextFormField(
                  controller: sugar,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Sugar (g)'),
                  validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0
                      ? 'Enter zero or more'
                      : null,
                ),
                TextFormField(
                  controller: fiber,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Fiber (g)'),
                  validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0
                      ? 'Enter zero or more'
                      : null,
                ),
                TextFormField(
                  controller: portion,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Portion size (g, optional)',
                  ),
                ),
                if (entryType == 'beverage')
                  TextFormField(
                    controller: volume,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Drink volume (ml, optional)',
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(context, [
                    title.text.trim(),
                    calories.text,
                    protein.text,
                    carbs.text,
                    fats.text,
                    entryType,
                    mealType,
                    portion.text,
                    volume.text,
                    sugar.text,
                    fiber.text,
                  ]);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    for (final controller in [
      title,
      calories,
      protein,
      carbs,
      fats,
      sugar,
      fiber,
      portion,
      volume,
    ]) {
      controller.dispose();
    }
    if (values == null) return;
    try {
      await supabase.from('nutrition_logs').insert({
        'entry_type': values[5],
        'title': values[0],
        'calories_kcal': int.parse(values[1]),
        'protein_g': double.parse(values[2]),
        'carbs_g': double.parse(values[3]),
        'fats_g': double.parse(values[4]),
        'meal_type': values[6],
        if (double.tryParse(values[7]) != null)
          'portion_g': double.parse(values[7]),
        if (int.tryParse(values[8]) != null) 'volume_ml': int.parse(values[8]),
        'nutrients': {
          'sugar_g': double.parse(values[9]),
          'fiber_g': double.parse(values[10]),
        },
        'estimate_source': 'manual',
      });
      await load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this entry. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> quickLogFood({
    required String title,
    required int calories,
    required double protein,
    required double carbs,
    required double fats,
    String type = 'food',
    int? volumeMl,
  }) async {
    try {
      await supabase.from('nutrition_logs').insert({
        'entry_type': type,
        'title': title,
        'meal_type': type == 'beverage' ? 'Drink' : 'Snack',
        'calories_kcal': calories,
        'protein_g': protein,
        'carbs_g': carbs,
        'fats_g': fats,
        'volume_ml': volumeMl,
        'estimate_source': 'quick_add_estimate',
      });
      await load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not add this entry. Try again.')),
        );
      }
    }
  }

  Widget quickAddCard() => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick food and drink log',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Tap a common item to add an approximate serving. You can adjust entries with the detailed log form.',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.restaurant, size: 18),
                label: const Text('Paneer quinoa · 620 kcal'),
                onPressed: () => quickLogFood(
                  title: 'Paneer quinoa bowl',
                  calories: 620,
                  protein: 42,
                  carbs: 68,
                  fats: 22,
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.restaurant, size: 18),
                label: const Text('Berry oats · 490 kcal'),
                onPressed: () => quickLogFood(
                  title: 'Berry protein oats',
                  calories: 490,
                  protein: 31,
                  carbs: 62,
                  fats: 14,
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.restaurant, size: 18),
                label: const Text('Chicken biryani · 780 kcal'),
                onPressed: () => quickLogFood(
                  title: 'Chicken biryani',
                  calories: 780,
                  protein: 48,
                  carbs: 88,
                  fats: 26,
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.restaurant, size: 18),
                label: const Text('Dal roti thali · 540 kcal'),
                onPressed: () => quickLogFood(
                  title: 'Dal roti thali',
                  calories: 540,
                  protein: 24,
                  carbs: 82,
                  fats: 13,
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.local_drink_outlined, size: 18),
                label: const Text('Orange juice · 250 ml'),
                onPressed: () => quickLogFood(
                  title: 'Orange juice',
                  calories: 112,
                  protein: 2,
                  carbs: 26,
                  fats: 0,
                  type: 'beverage',
                  volumeMl: 250,
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.local_drink_outlined, size: 18),
                label: const Text('Milk coffee · 240 ml'),
                onPressed: () => quickLogFood(
                  title: 'Milk coffee',
                  calories: 90,
                  protein: 4,
                  carbs: 10,
                  fats: 3,
                  type: 'beverage',
                  volumeMl: 240,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget metricCard(
    String title,
    TextEditingController controller,
    String suffix,
    IconData icon,
  ) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff0ba787)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              Text(suffix),
            ],
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'VitalPulse',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        if (healthSyncSupported)
          IconButton(
            tooltip: syncingHealth
                ? 'Syncing device health…'
                : 'Sync Apple Health / Health Connect',
            onPressed: syncingHealth ? null : syncDeviceHealth,
            icon: syncingHealth
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.watch_outlined),
          ),
        IconButton(
          tooltip: scanning ? 'Analyzing meal photo…' : 'Scan meal photo',
          onPressed: scanning ? null : scanMealPhoto,
          icon: scanning
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.document_scanner_outlined),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: () => supabase.auth.signOut(),
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: addMeal,
      icon: const Icon(Icons.add),
      label: const Text('Log meal'),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 96),
              children: [
                Text(
                  'Good day, ${name.text}',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Text('Your health snapshot for today'),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      message!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                Card(
                  color: const Color(0xffe0f5ee),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Color(0xff098265),
                          size: 34,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Food energy logged'),
                              Text(
                                '$totalCalories kcal',
                                style: const TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text('${meals.length} entries'),
                      ],
                    ),
                  ),
                ),
                profileCard(),
                const SizedBox(height: 20),
                Text(
                  'Daily habits',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth > 900
                        ? 4
                        : constraints.maxWidth > 500
                        ? 2
                        : 1;
                    final cardWidth = columns == 1
                        ? constraints.maxWidth
                        : (constraints.maxWidth - (columns - 1) * 10) / columns;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: metricCard(
                            'Steps',
                            steps,
                            'steps',
                            Icons.directions_walk,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: metricCard(
                            'Water',
                            water,
                            'ml',
                            Icons.water_drop_outlined,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: metricCard(
                            'Sleep',
                            sleep,
                            'hours',
                            Icons.bedtime_outlined,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: metricCard(
                            'Heart rate',
                            heartRate,
                            'bpm',
                            Icons.favorite_outline,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: saveMetrics,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save today’s metrics'),
                  ),
                ),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.watch_outlined,
                          color: Color(0xff098265),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            kIsWeb
                                ? 'Connect from the mobile app'
                                : defaultTargetPlatform == TargetPlatform.iOS
                                ? 'Apple Health'
                                : defaultTargetPlatform ==
                                      TargetPlatform.android
                                ? 'Health Connect'
                                : 'Unavailable on this device',
                          ),
                        ),
                        if (healthSyncSupported)
                          IconButton(
                            tooltip: 'Read device health data',
                            onPressed: syncingHealth ? null : syncDeviceHealth,
                            icon: syncingHealth
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.sync),
                          ),
                      ],
                    ),
                  ),
                ),
                hydrationCard(),
                sleepCoachCard(),
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xff098265),
                    ),
                    title: const Text('Scan a meal photo'),
                    subtitle: const Text(
                      'Photo is sent to your configured AI provider for a nutrition estimate. Review before saving.',
                    ),
                    trailing: scanning
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: scanning ? null : scanMealPhoto,
                  ),
                ),
                quickAddCard(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Today’s nutrition',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: addMeal,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                if (meals.isEmpty)
                  const Card(
                    elevation: 0,
                    child: Padding(
                      padding: EdgeInsets.all(22),
                      child: Text(
                        'No meals logged yet. Add your first meal to start tracking.',
                      ),
                    ),
                  )
                else
                  ...meals.map(
                    (m) => Card(
                      elevation: 0,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xffe0f5ee),
                          child: Icon(
                            m['entry_type'] == 'beverage'
                                ? Icons.local_drink_outlined
                                : Icons.restaurant,
                            color: const Color(0xff098265),
                          ),
                        ),
                        title: Text('${m['title']}'),
                        subtitle: Text(
                          '${m['calories_kcal']} kcal  •  ${m['protein_g']} g protein',
                        ),
                        trailing: IconButton(
                          tooltip: 'Delete entry',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await supabase
                                .from('nutrition_logs')
                                .delete()
                                .eq('id', m['id']);
                            await load();
                          },
                        ),
                      ),
                    ),
                  ),
                Card(
                  elevation: 0,
                  child: ExpansionTile(
                    leading: const Icon(
                      Icons.biotech_outlined,
                      color: Color(0xff098265),
                    ),
                    title: const Text('Deep nutrition summary'),
                    subtitle: Text(
                      '${totalProtein.toStringAsFixed(1)} g protein · ${totalCarbs.toStringAsFixed(1)} g carbs · ${totalFats.toStringAsFixed(1)} g fat',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalCalories kcal across ${meals.length} logged food and beverage entries.',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Meal photos can provide approximate calories and macronutrients. Review every estimate before saving; beverage and micronutrient values can be entered manually.',
                            ),
                            for (final meal in meals.where(
                              (m) => m['nutrients'] is Map,
                            ))
                              Text(
                                '${meal['title']}: ${jsonEncode(meal['nutrients'])}',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                historyCard(),
              ],
            ),
          ),
  );
}
