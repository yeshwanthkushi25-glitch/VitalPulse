import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
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
    home: supabaseUrl.isEmpty || supabaseAnonKey.isEmpty
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
                  'Run the database migration, then start this app with SUPABASE_URL and SUPABASE_ANON_KEY provided as Dart compile-time values. Never use a service-role key in the app.',
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
  final name = TextEditingController();
  final steps = TextEditingController(text: '0'),
      water = TextEditingController(text: '0'),
      sleep = TextEditingController(text: '0');
  List<Map<String, dynamic>> meals = [];
  bool loading = true;
  String? message;
  String get date => DateTime.now().toIso8601String().substring(0, 10);
  int get totalCalories =>
      meals.fold(0, (v, m) => v + ((m['calories_kcal'] as num?)?.round() ?? 0));
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    name.dispose();
    steps.dispose();
    water.dispose();
    sleep.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final user = supabase.auth.currentUser!;
      final profile = await supabase
          .from('profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle();
      final logs = await supabase
          .from('nutrition_logs')
          .select('id,title,calories_kcal,protein_g,entry_type,logged_at')
          .gte('logged_at', '${date}T00:00:00')
          .order('logged_at', ascending: false);
      final health = await supabase
          .from('daily_health_logs')
          .select('steps,water_ml,sleep_hours')
          .eq('log_date', date)
          .maybeSingle();
      if (!mounted) return;
      name.text = (profile?['display_name'] as String?)?.isNotEmpty == true
          ? profile!['display_name'] as String
          : user.email?.split('@').first ?? 'friend';
      meals = List<Map<String, dynamic>>.from(logs);
      if (health != null) {
        steps.text = '${health['steps']}';
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
        'water_ml': int.tryParse(water.text) ?? 0,
        'sleep_hours': double.tryParse(sleep.text) ?? 0,
      }, onConflict: 'user_id,log_date');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Today’s metrics saved')));
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

  Future<void> addMeal() async {
    final title = TextEditingController(),
        calories = TextEditingController(),
        protein = TextEditingController();
    final form = GlobalKey<FormState>();
    var entryType = 'food';
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
                    entryType,
                  ]);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (values == null) return;
    try {
      await supabase.from('nutrition_logs').insert({
        'entry_type': values[3],
        'title': values[0],
        'calories_kcal': int.parse(values[1]),
        'protein_g': double.parse(values[2]),
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
                const SizedBox(height: 20),
                Text(
                  'Daily habits',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 650;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        SizedBox(
                          width: wide
                              ? (constraints.maxWidth - 20) / 3
                              : constraints.maxWidth,
                          child: metricCard(
                            'Steps',
                            steps,
                            'steps',
                            Icons.directions_walk,
                          ),
                        ),
                        SizedBox(
                          width: wide
                              ? (constraints.maxWidth - 20) / 3
                              : constraints.maxWidth,
                          child: metricCard(
                            'Water',
                            water,
                            'ml',
                            Icons.water_drop_outlined,
                          ),
                        ),
                        SizedBox(
                          width: wide
                              ? (constraints.maxWidth - 20) / 3
                              : constraints.maxWidth,
                          child: metricCard(
                            'Sleep',
                            sleep,
                            'hours',
                            Icons.bedtime_outlined,
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
              ],
            ),
          ),
  );
}
