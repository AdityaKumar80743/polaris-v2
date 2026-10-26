import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121214),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const PolarisApp());
}

/// ============================================================================
/// DESIGN TOKENS — NATIVE iOS / MATERIAL DARK PALETTE (OLED #000000 + #1C1C1E)
/// ============================================================================
class PolarisColors {
  static const Color bg = Color(0xFF000000);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surfaceElevated = Color(0xFF242426);
  static const Color inputFill = Color(0xFF2C2C2E);
  static const Color divider = Color(0xFF2C2C2E);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);

  static const Color coral = Color(0xFFFF5500);
  static const Color crimson = Color(0xFFFA114F);
  static const Color green = Color(0xFF30D158);
  static const Color blue = Color(0xFF0A84FF);
  static const Color amber = Color(0xFFFF9F0A);
  static const Color purple = Color(0xFFBF5AF2);
}

class PolarisApp extends StatelessWidget {
  const PolarisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polaris',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: PolarisColors.bg,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: PolarisColors.coral,
          secondary: PolarisColors.green,
          surface: PolarisColors.surface,
          error: PolarisColors.crimson,
        ),
        splashFactory: InkSparkle.splashFactory,
      ),
      home: const PolarisShell(),
    );
  }
}

/// ============================================================================
/// DOMAIN MODELS WITH FULL JSON SERIALIZATION
/// ============================================================================
class WorkoutSession {
  final String id;
  String name;
  String category;
  String freqType; // 'daily' | '6hours' | 'custom'
  int customVal;
  String customUnit; // 'hours' | 'days' | 'minutes'
  int completedToday;
  int dailyTargetSets;
  String nextDueText;

  WorkoutSession({
    required this.id,
    required this.name,
    required this.category,
    required this.freqType,
    this.customVal = 4,
    this.customUnit = 'hours',
    this.completedToday = 0,
    this.dailyTargetSets = 3,
    required this.nextDueText,
  });

  String get freqLabel {
    if (freqType == 'daily') return 'Daily (24h)';
    if (freqType == '6hours') return 'Every 6 Hours';
    return 'Every $customVal $customUnit';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'freqType': freqType,
        'customVal': customVal,
        'customUnit': customUnit,
        'completedToday': completedToday,
        'dailyTargetSets': dailyTargetSets,
        'nextDueText': nextDueText,
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> j) => WorkoutSession(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? 'Exercise',
        category: j['category']?.toString() ?? 'Strength',
        freqType: j['freqType']?.toString() ?? 'daily',
        customVal: (j['customVal'] as num?)?.toInt() ?? 4,
        customUnit: j['customUnit']?.toString() ?? 'hours',
        completedToday: (j['completedToday'] as num?)?.toInt() ?? 0,
        dailyTargetSets: (j['dailyTargetSets'] as num?)?.toInt() ?? 3,
        nextDueText: j['nextDueText']?.toString() ?? 'Due Today',
      );
}

class TaskItem {
  final String id;
  String title;
  String priority; // 'high' | 'medium' | 'low'
  String repeat; // 'none' | 'daily' | 'weekly' | 'custom'
  String customRepeat;
  bool hasDeadline;
  String dueDate; // YYYY-MM-DD
  String dueTime; // HH:mm
  bool completed;

  TaskItem({
    required this.id,
    required this.title,
    this.priority = 'medium',
    this.repeat = 'none',
    this.customRepeat = '',
    this.hasDeadline = true,
    this.dueDate = '',
    this.dueTime = '09:30',
    this.completed = false,
  });

  String get repeatLabel {
    if (repeat == 'none') return 'One-Time';
    if (repeat == 'daily') return 'Daily';
    if (repeat == 'weekly') return 'Weekly';
    return customRepeat.isNotEmpty ? customRepeat : 'Custom';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'priority': priority,
        'repeat': repeat,
        'customRepeat': customRepeat,
        'hasDeadline': hasDeadline,
        'dueDate': dueDate,
        'dueTime': dueTime,
        'completed': completed,
      };

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        priority: j['priority']?.toString() ?? 'medium',
        repeat: j['repeat']?.toString() ?? 'none',
        customRepeat: j['customRepeat']?.toString() ?? '',
        hasDeadline: j['hasDeadline'] as bool? ?? false,
        dueDate: j['dueDate']?.toString() ?? '',
        dueTime: j['dueTime']?.toString() ?? '09:30',
        completed: j['completed'] as bool? ?? false,
      );
}

class WaterLogItem {
  final String id;
  final int amount;
  final String label;
  final String time;

  WaterLogItem({
    required this.id,
    required this.amount,
    required this.label,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'label': label,
        'time': time,
      };

  factory WaterLogItem.fromJson(Map<String, dynamic> j) => WaterLogItem(
        id: j['id']?.toString() ?? '',
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        label: j['label']?.toString() ?? 'Hydration',
        time: j['time']?.toString() ?? '',
      );
}

class MealEntry {
  final String id;
  final String name;
  final int grams;
  final String slot;
  final int calories;
  final int carbs;
  final int protein;
  final int fiber;
  final int fat;
  final String time;

  MealEntry({
    required this.id,
    required this.name,
    required this.grams,
    required this.slot,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fiber,
    required this.fat,
    this.time = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'grams': grams,
        'slot': slot,
        'calories': calories,
        'carbs': carbs,
        'protein': protein,
        'fiber': fiber,
        'fat': fat,
        'time': time,
      };

  factory MealEntry.fromJson(Map<String, dynamic> j) => MealEntry(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        grams: (j['grams'] as num?)?.toInt() ?? 100,
        slot: j['slot']?.toString() ?? 'Meal',
        calories: (j['calories'] as num?)?.toInt() ?? 0,
        carbs: (j['carbs'] as num?)?.toInt() ?? 0,
        protein: (j['protein'] as num?)?.toInt() ?? 0,
        fiber: (j['fiber'] as num?)?.toInt() ?? 0,
        fat: (j['fat'] as num?)?.toInt() ?? 0,
        time: j['time']?.toString() ?? '',
      );
}

class ExpenseCategoryItem {
  final String id;
  final String name;
  final String icon;
  final int colorHex;

  const ExpenseCategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'colorHex': colorHex,
      };

  factory ExpenseCategoryItem.fromJson(Map<String, dynamic> j) =>
      ExpenseCategoryItem(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? 'General',
        icon: j['icon']?.toString() ?? '💳',
        colorHex: (j['colorHex'] as num?)?.toInt() ?? 0xFF0A84FF,
      );
}

class ExpenseItem {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String method;
  final String time;
  final String date;

  ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.method = 'Card',
    required this.time,
    this.date = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'method': method,
        'time': time,
        'date': date,
      };

  factory ExpenseItem.fromJson(Map<String, dynamic> j) => ExpenseItem(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
        category: j['category']?.toString() ?? 'Food & Dining',
        method: j['method']?.toString() ?? 'Card',
        time: j['time']?.toString() ?? '',
        date: j['date']?.toString() ?? '',
      );
}

class JournalEntry {
  final String id;
  final String type; // 'voice' | 'text'
  String title;
  String mood;
  final String duration;
  String body;
  final String time;
  final String date;
  final String? audioFilePath;

  JournalEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.mood,
    this.duration = '',
    required this.body,
    required this.time,
    this.date = '',
    this.audioFilePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'mood': mood,
        'duration': duration,
        'body': body,
        'time': time,
        'date': date,
        'audioFilePath': audioFilePath,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id']?.toString() ?? '',
        type: j['type']?.toString() ?? 'text',
        title: j['title']?.toString() ?? '',
        mood: j['mood']?.toString() ?? '🔥 Focused',
        duration: j['duration']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        time: j['time']?.toString() ?? '',
        date: j['date']?.toString() ?? '',
        audioFilePath: j['audioFilePath']?.toString(),
      );
}

class TimelineEvent {
  final String id;
  final String category; // 'workout' | 'todo' | 'water' | 'meal' | 'expense' | 'journal' | 'streak'
  final String title;
  final String badge;
  final String time;
  final String date;

  TimelineEvent({
    required this.id,
    required this.category,
    required this.title,
    required this.badge,
    required this.time,
    this.date = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'title': title,
        'badge': badge,
        'time': time,
        'date': date,
      };

  factory TimelineEvent.fromJson(Map<String, dynamic> j) => TimelineEvent(
        id: j['id']?.toString() ?? '',
        category: j['category']?.toString() ?? 'journal',
        title: j['title']?.toString() ?? '',
        badge: j['badge']?.toString() ?? '',
        time: j['time']?.toString() ?? '',
        date: j['date']?.toString() ?? '',
      );
}

class FoodItemRef {
  final String id;
  final String name;
  final int cal;
  final double carb;
  final double prot;
  final double fiber;
  final double fat;
  final bool isCustom;

  const FoodItemRef({
    required this.id,
    required this.name,
    required this.cal,
    required this.carb,
    required this.prot,
    required this.fiber,
    required this.fat,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cal': cal,
        'carb': carb,
        'prot': prot,
        'fiber': fiber,
        'fat': fat,
        'isCustom': isCustom,
      };

  factory FoodItemRef.fromJson(Map<String, dynamic> j) => FoodItemRef(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? 'Food',
        cal: (j['cal'] as num?)?.toInt() ?? 100,
        carb: (j['carb'] as num?)?.toDouble() ?? 10.0,
        prot: (j['prot'] as num?)?.toDouble() ?? 10.0,
        fiber: (j['fiber'] as num?)?.toDouble() ?? 2.0,
        fat: (j['fat'] as num?)?.toDouble() ?? 3.0,
        isCustom: j['isCustom'] as bool? ?? true,
      );
}

const List<FoodItemRef> defaultFoodCatalog = [
  FoodItemRef(id: 'oatmeal_protein', name: 'Oatmeal with Protein', cal: 340, carb: 48, prot: 28, fiber: 8, fat: 6),
  FoodItemRef(id: 'chicken_breast', name: 'Grilled Chicken Breast', cal: 165, carb: 0, prot: 31, fiber: 0, fat: 3.6),
  FoodItemRef(id: 'rolled_oats', name: 'Rolled Oats', cal: 389, carb: 66, prot: 16.9, fiber: 10.6, fat: 6.9),
  FoodItemRef(id: 'whole_eggs', name: 'Whole Eggs (Boiled/Scrambled)', cal: 155, carb: 1.1, prot: 13, fiber: 0, fat: 11),
  FoodItemRef(id: 'brown_rice', name: 'Cooked Brown Rice', cal: 123, carb: 25.6, prot: 2.7, fiber: 1.8, fat: 1.0),
  FoodItemRef(id: 'greek_yogurt', name: 'Greek Yogurt (High Protein)', cal: 97, carb: 3.9, prot: 10, fiber: 0, fat: 5),
  FoodItemRef(id: 'whey_isolate', name: 'Whey Protein Isolate', cal: 370, carb: 6, prot: 82, fiber: 0, fat: 2),
  FoodItemRef(id: 'salmon_fillet', name: 'Atlantic Salmon Fillet', cal: 208, carb: 0, prot: 20.4, fiber: 0, fat: 13.4),
  FoodItemRef(id: 'paneer_cottage', name: 'Paneer / Cottage Cheese', cal: 265, carb: 3.4, prot: 18.3, fiber: 0, fat: 20.8),
  FoodItemRef(id: 'cooked_lentils', name: 'Cooked Dal / Lentils', cal: 116, carb: 20.1, prot: 9.0, fiber: 7.9, fat: 0.4),
  FoodItemRef(id: 'banana', name: 'Ripe Banana', cal: 89, carb: 22.8, prot: 1.1, fiber: 2.6, fat: 0.3),
  FoodItemRef(id: 'almonds', name: 'Raw Almonds', cal: 579, carb: 21.6, prot: 21.2, fiber: 12.5, fat: 49.9),
  FoodItemRef(id: 'avocado', name: 'Fresh Avocado', cal: 160, carb: 8.5, prot: 2.0, fiber: 6.7, fat: 14.7),
];

const List<ExpenseCategoryItem> defaultExpenseCategories = [
  ExpenseCategoryItem(id: 'cat_food', name: 'Food & Dining', icon: '🥗', colorHex: 0xFF30D158),
  ExpenseCategoryItem(id: 'cat_transport', name: 'Transport', icon: '🚇', colorHex: 0xFF0A84FF),
  ExpenseCategoryItem(id: 'cat_gym', name: 'Fitness & Gym', icon: '🏋️', colorHex: 0xFFFF5500),
  ExpenseCategoryItem(id: 'cat_bills', name: 'Bills & Utilities', icon: '⚡', colorHex: 0xFFFF9F0A),
  ExpenseCategoryItem(id: 'cat_groceries', name: 'Groceries', icon: '🛒', colorHex: 0xFFFA114F),
  ExpenseCategoryItem(id: 'cat_supps', name: 'Supplements', icon: '💊', colorHex: 0xFFBF5AF2),
];

/// ============================================================================
/// MAIN APPLICATION SHELL & LIFECYCLE STATE
/// ============================================================================
class PolarisShell extends StatefulWidget {
  const PolarisShell({super.key});

  @override
  State<PolarisShell> createState() => _PolarisShellState();
}

class _PolarisShellState extends State<PolarisShell> with WidgetsBindingObserver {
  static const String _storageKey = 'polaris_flutter_state_v3';

  // Active Navigation Key ('home', 'workout', 'todo', 'fuel', 'expense', 'journal')
  String _activeModuleKey = 'home';

  // Enabled Modules (Users can add/remove modules dynamically)
  List<String> _enabledModules = ['workout', 'todo', 'fuel', 'expense', 'journal'];

  // User Profile & Preferences
  String _userName = 'Athlete';
  String _currencySymbol = '₹';
  bool _showOnboardingBanner = true;

  // Daily Rollover & Streak Engine State
  String _lastActiveDate = '';
  int _currentStreak = 0;
  int _bestStreak = 0;
  String _lastStreakAwardedDate = '';
  Set<String> _streakCompletedDates = {};
  int _dailyGoalStreakThreshold = 80; // % daily completion required for automatic streak

  // Sub-navigation & view state
  int _todoScheduleSubTab = 0; // 0: Tasks, 1: Visual Schedule
  String _scheduleViewMode = 'all'; // 'all' | 'month' | 'time'
  String _todoFilter = 'all'; // 'all' | 'active' | 'repeating' | 'nodeadline' | 'done'
  int _fuelSubTab = 0; // 0: Meals, 1: Diet Plan, 2: Water
  int _journalSubTab = 0; // 0: Journal, 1: Timeline
  String _journalFilter = 'all'; // 'all' | 'voice' | 'text'
  String _timelineFilter = 'all'; // 'all' | 'workout' | 'todo' | 'water' | 'meal' | 'expense' | 'journal' | 'streak'
  String _expenseFilter = 'all';

  late String _selectedDate;
  late DateTime _calendarMonth;

  // Stopwatch & Background Timestamp Tracking
  Timer? _stopwatchTimer;
  Timer? _midnightWatcherTimer;
  int _stopwatchSeconds = 0;
  DateTime? _stopwatchLastTick;

  // Real Voice Recorder & Audio Player
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _voiceTimer;
  int _voiceSeconds = 0;
  bool _isRecordingVoice = false;
  String? _currentRecordingPath;
  String? _activePlayingVoiceId;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  // Persistent Data Collections (Fresh by default for every new user!)
  List<WorkoutSession> _workouts = [];
  List<TaskItem> _tasks = [];
  int _waterMl = 0;
  int _waterTarget = 2500;
  List<WaterLogItem> _waterHistory = [];
  List<FoodItemRef> _foodCatalog = List.from(defaultFoodCatalog);
  List<MealEntry> _meals = [];
  List<ExpenseCategoryItem> _expenseCategories = List.from(defaultExpenseCategories);
  List<ExpenseItem> _expenses = [];
  List<JournalEntry> _journals = [];
  List<TimelineEvent> _timeline = [];

  // Nutrition Targets & Biometric Diet Planner State
  int _targetCal = 2400;
  int _targetCarb = 250;
  int _targetProt = 150;
  int _targetFiber = 35;
  int _targetFat = 70;
  bool _showMacroTargetEditor = false;
  bool _isCustomFoodMode = false;
  bool _saveCustomFoodToCatalog = true;

  int _age = 25;
  int _heightCm = 175;
  int _weightKg = 72;
  String _gender = 'male';
  double _activityFactor = 1.55;
  String _goal = 'leangain';

  // Form Selection State
  String _workoutCategory = 'Strength';
  String _workoutFreq = 'daily';
  String _workoutCustomUnit = 'hours';

  String _taskRepeat = 'none';
  String _taskPriority = 'medium';
  bool _taskHasDeadline = true;
  late String _taskDraftDate;
  String _taskDraftTime = '09:30';

  String _selectedFoodId = defaultFoodCatalog.first.id;
  String _selectedMealSlot = 'Breakfast';

  String _selectedExpenseCategory = 'Food & Dining';
  String _selectedExpenseMethod = 'Card';
  bool _showCustomCategoryCreator = false;
  String _newCategoryIcon = '☕';

  String _selectedVoiceMood = '🔥 Focused';
  String _selectedTextMood = '🧭 Reflective';

  // Lifecycle-safe Form Controllers
  late final TextEditingController _workoutNameCtrl;
  late final TextEditingController _workoutCustomValCtrl;
  late final TextEditingController _workoutTargetSetsCtrl;

  late final TextEditingController _taskTitleCtrl;
  late final TextEditingController _taskCustomRepeatCtrl;

  late final TextEditingController _mealQtyCtrl;
  late final TextEditingController _customFoodNameCtrl;
  late final TextEditingController _customFoodCalCtrl;
  late final TextEditingController _customFoodCarbCtrl;
  late final TextEditingController _customFoodProtCtrl;
  late final TextEditingController _customFoodFiberCtrl;

  late final TextEditingController _targetCalCtrl;
  late final TextEditingController _targetCarbCtrl;
  late final TextEditingController _targetProtCtrl;
  late final TextEditingController _targetFiberCtrl;
  late final TextEditingController _targetFatCtrl;

  late final TextEditingController _planAgeCtrl;
  late final TextEditingController _planHeightCtrl;
  late final TextEditingController _planWeightCtrl;

  late final TextEditingController _waterCustomCtrl;
  late final TextEditingController _waterTargetCtrl;

  late final TextEditingController _expDescCtrl;
  late final TextEditingController _expAmountCtrl;
  late final TextEditingController _newCatNameCtrl;

  late final TextEditingController _voiceTitleCtrl;
  late final TextEditingController _journalTitleCtrl;
  late final TextEditingController _journalBodyCtrl;
  late final TextEditingController _milestoneNoteCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final now = DateTime.now();
    _selectedDate = _formatIsoDate(now);
    _taskDraftDate = _selectedDate;
    _lastActiveDate = _selectedDate;
    _calendarMonth = DateTime(now.year, now.month, 1);

    _workoutNameCtrl = TextEditingController();
    _workoutCustomValCtrl = TextEditingController(text: '4');
    _workoutTargetSetsCtrl = TextEditingController(text: '3');

    _taskTitleCtrl = TextEditingController();
    _taskCustomRepeatCtrl = TextEditingController(text: 'Every 2 days');

    _mealQtyCtrl = TextEditingController(text: '150');
    _customFoodNameCtrl = TextEditingController();
    _customFoodCalCtrl = TextEditingController(text: '200');
    _customFoodCarbCtrl = TextEditingController(text: '20');
    _customFoodProtCtrl = TextEditingController(text: '25');
    _customFoodFiberCtrl = TextEditingController(text: '4');

    _targetCalCtrl = TextEditingController(text: '$_targetCal');
    _targetCarbCtrl = TextEditingController(text: '$_targetCarb');
    _targetProtCtrl = TextEditingController(text: '$_targetProt');
    _targetFiberCtrl = TextEditingController(text: '$_targetFiber');
    _targetFatCtrl = TextEditingController(text: '$_targetFat');

    _planAgeCtrl = TextEditingController(text: '$_age');
    _planHeightCtrl = TextEditingController(text: '$_heightCm');
    _planWeightCtrl = TextEditingController(text: '$_weightKg');

    _waterCustomCtrl = TextEditingController(text: '300');
    _waterTargetCtrl = TextEditingController(text: '$_waterTarget');

    _expDescCtrl = TextEditingController();
    _expAmountCtrl = TextEditingController();
    _newCatNameCtrl = TextEditingController();

    _voiceTitleCtrl = TextEditingController();
    _journalTitleCtrl = TextEditingController();
    _journalBodyCtrl = TextEditingController();
    _milestoneNoteCtrl = TextEditingController();

    // AudioPlayer listeners for real voice playback
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _activePlayingVoiceId = null;
          _audioPosition = Duration.zero;
        });
      }
    });
    _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted && _activePlayingVoiceId != null) {
        setState(() => _audioPosition = pos);
      }
    });
    _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted && _activePlayingVoiceId != null) {
        setState(() => _audioDuration = dur);
      }
    });

    // Periodic watcher to catch midnight rollover while app is open
    _midnightWatcherTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkAndPerformDailyReset();
    });

    _loadPersistedState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopwatchTimer?.cancel();
    _midnightWatcherTimer?.cancel();
    _voiceTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();

    _workoutNameCtrl.dispose();
    _workoutCustomValCtrl.dispose();
    _workoutTargetSetsCtrl.dispose();
    _taskTitleCtrl.dispose();
    _taskCustomRepeatCtrl.dispose();
    _mealQtyCtrl.dispose();
    _customFoodNameCtrl.dispose();
    _customFoodCalCtrl.dispose();
    _customFoodCarbCtrl.dispose();
    _customFoodProtCtrl.dispose();
    _customFoodFiberCtrl.dispose();
    _targetCalCtrl.dispose();
    _targetCarbCtrl.dispose();
    _targetProtCtrl.dispose();
    _targetFiberCtrl.dispose();
    _targetFatCtrl.dispose();
    _planAgeCtrl.dispose();
    _planHeightCtrl.dispose();
    _planWeightCtrl.dispose();
    _waterCustomCtrl.dispose();
    _waterTargetCtrl.dispose();
    _expDescCtrl.dispose();
    _expAmountCtrl.dispose();
    _newCatNameCtrl.dispose();
    _voiceTitleCtrl.dispose();
    _journalTitleCtrl.dispose();
    _journalBodyCtrl.dispose();
    _milestoneNoteCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_stopwatchTimer != null && _stopwatchLastTick != null) {
        final now = DateTime.now();
        final diff = now.difference(_stopwatchLastTick!).inSeconds;
        if (diff > 0) {
          setState(() {
            _stopwatchSeconds += diff;
            _stopwatchLastTick = now;
          });
        }
      }
      _checkAndPerformDailyReset();
    }
  }

  /// ==========================================================================
  /// DATE HELPERS & AUTOMATIC DAILY MIDNIGHT ROLLOVER ENGINE
  /// ==========================================================================
  String _formatIsoDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _todayIsoDate() => _formatIsoDate(DateTime.now());

  String _formatShortDateLabel(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String _formatFullDayHeader(DateTime dt) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  String _formatMonthYearHeader(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  /// Checks if the calendar date has rolled over since `_lastActiveDate`.
  /// When a new day begins:
  /// 1. Evaluates streak continuity (if more than 1 day passed without completing daily goal, resets `_currentStreak` to 0).
  /// 2. Resets daily workout sets (`completedToday = 0`), stopwatch (`0`), water (`0 ml` & empty history), and daily logged meals (`_meals.clear()`).
  /// 3. Unchecks completed repeating tasks (`daily`, `weekly`, `custom`) and advances their due date to the next occurrence on or after today.
  void _checkAndPerformDailyReset({bool forceManualReset = false}) {
    final todayIso = _todayIsoDate();
    if (!forceManualReset && (_lastActiveDate.isEmpty || _lastActiveDate == todayIso)) {
      _lastActiveDate = todayIso;
      return;
    }

    final previousDate = _lastActiveDate;
    final prevMealsCount = _meals.length;
    final prevWater = _waterMl;
    final prevSets = _workouts.fold<int>(0, (sum, w) => sum + w.completedToday);

    setState(() {
      // 1. Evaluate streak continuity across calendar rollover
      if (!forceManualReset && _lastStreakAwardedDate.isNotEmpty) {
        final lastStreakDt = DateTime.tryParse('${_lastStreakAwardedDate}T00:00:00');
        final todayDt = DateTime.tryParse('${todayIso}T00:00:00');
        if (lastStreakDt != null && todayDt != null) {
          final gapDays = todayDt.difference(lastStreakDt).inDays;
          if (gapDays > 1) {
            _currentStreak = 0;
          }
        }
      }

      // 2. Archive yesterday's summary in Timeline before resetting if there was activity
      if (prevSets > 0 || prevWater > 0 || prevMealsCount > 0) {
        _timeline.insert(
          0,
          TimelineEvent(
            id: 'tl_rollover_${DateTime.now().millisecondsSinceEpoch}',
            category: 'streak',
            title: 'Daily Reset ($previousDate Summary)',
            badge: '$prevSets sets • ${prevWater}ml • $prevMealsCount meals',
            time: '12:00 AM',
            date: _formatShortDateLabel(DateTime.now()),
          ),
        );
      }

      // 3. Reset Workout Daily Sets & Stopwatch
      for (final w in _workouts) {
        w.completedToday = 0;
        w.nextDueText = 'Due Today';
      }
      _stopwatchSeconds = 0;
      _stopwatchTimer?.cancel();
      _stopwatchTimer = null;

      // 4. Reset Water Tracker for the new day
      _waterMl = 0;
      _waterHistory.clear();

      // 5. Reset Daily Meal Logs (preserving user's macro targets & food catalog)
      _meals.clear();

      // 6. Reset Repeating Tasks & Advance Due Date to Next Occurrence
      for (final t in _tasks) {
        if (t.repeat != 'none') {
          t.completed = false;
          if (t.hasDeadline && t.dueDate.isNotEmpty) {
            t.dueDate = _computeNextRepeatingDate(t, todayIso);
          }
        }
      }

      _lastActiveDate = todayIso;
      _selectedDate = todayIso;
      _taskDraftDate = todayIso;
    });

    _saveState();
    if (forceManualReset && mounted) {
      _showToast('Daily progress reset for a fresh day');
    }
  }

  String _computeNextRepeatingDate(TaskItem t, String todayIso) {
    final start = DateTime.tryParse('${t.dueDate}T00:00:00');
    final today = DateTime.tryParse('${todayIso}T00:00:00');
    if (start == null || today == null || !today.isAfter(start)) return todayIso;

    if (t.repeat == 'daily') return todayIso;
    final diffDays = today.difference(start).inDays;
    if (t.repeat == 'weekly') {
      final rem = diffDays % 7;
      final nextDt = rem == 0 ? today : today.add(Duration(days: 7 - rem));
      return _formatIsoDate(nextDt);
    }
    if (t.repeat == 'custom') {
      final match = RegExp(r'(\d+)').firstMatch(t.customRepeat);
      final step = match != null ? math.max(1, int.tryParse(match.group(1)!) ?? 2) : 2;
      final rem = diffDays % step;
      final nextDt = rem == 0 ? today : today.add(Duration(days: step - rem));
      return _formatIsoDate(nextDt);
    }
    return todayIso;
  }

  /// ==========================================================================
  /// DAILY GOAL SCORE & STREAK ENGINE
  /// ==========================================================================
  int _calculateDailyGoalPercent() {
    final List<double> activeScores = [];

    if (_enabledModules.contains('workout')) {
      final totalTargetSets = _workouts.fold<int>(0, (s, w) => s + math.max(1, w.dailyTargetSets));
      final totalDoneSets = _workouts.fold<int>(0, (s, w) => s + w.completedToday);
      final workoutScore = totalTargetSets > 0
          ? (totalDoneSets / totalTargetSets * 100).clamp(0.0, 100.0)
          : (totalDoneSets > 0 ? 100.0 : 0.0);
      activeScores.add(workoutScore);
    }

    if (_enabledModules.contains('todo')) {
      final todayIso = _todayIsoDate();
      final todayTasks = _tasks.where((t) => !t.hasDeadline || _doesTaskOccurOnDate(t, todayIso)).toList();
      final doneCount = todayTasks.where((t) => t.completed).length;
      final todoScore = todayTasks.isNotEmpty
          ? (doneCount / todayTasks.length * 100).clamp(0.0, 100.0)
          : 0.0;
      activeScores.add(todoScore);
    }

    if (_enabledModules.contains('fuel')) {
      final waterPct = (_waterMl / math.max(1, _waterTarget) * 100).clamp(0.0, 100.0);
      final totalCal = _meals.fold<int>(0, (s, m) => s + m.calories);
      final calPct = (totalCal / math.max(1, _targetCal) * 100).clamp(0.0, 100.0);
      activeScores.add(waterPct);
      activeScores.add(calPct);
    }

    if (activeScores.isEmpty) return 0;
    final avg = activeScores.reduce((a, b) => a + b) / activeScores.length;
    return avg.round().clamp(0, 100);
  }

  void _evaluateStreakOnProgress() {
    final todayIso = _todayIsoDate();
    if (_streakCompletedDates.contains(todayIso)) return;

    final score = _calculateDailyGoalPercent();
    if (score >= _dailyGoalStreakThreshold) {
      _awardStreakForToday(autoTriggered: true);
    }
  }

  void _awardStreakForToday({bool autoTriggered = false}) {
    final todayIso = _todayIsoDate();
    if (_streakCompletedDates.contains(todayIso)) {
      if (!autoTriggered) {
        _showToast('Today\'s streak ($_currentStreak days) is already locked in! 🔥');
      }
      return;
    }

    setState(() {
      if (_lastStreakAwardedDate.isNotEmpty) {
        final prevDt = DateTime.tryParse('${_lastStreakAwardedDate}T00:00:00');
        final todayDt = DateTime.tryParse('${todayIso}T00:00:00');
        if (prevDt != null && todayDt != null && todayDt.difference(prevDt).inDays == 1) {
          _currentStreak += 1;
        } else if (_lastStreakAwardedDate == todayIso) {
          // Already counted
        } else {
          _currentStreak = 1;
        }
      } else {
        _currentStreak = 1;
      }

      if (_currentStreak > _bestStreak) {
        _bestStreak = _currentStreak;
      }
      _lastStreakAwardedDate = todayIso;
      _streakCompletedDates.add(todayIso);

      _timeline.insert(
        0,
        TimelineEvent(
          id: 'tl_streak_${DateTime.now().millisecondsSinceEpoch}',
          category: 'streak',
          title: 'Daily Goal Completed — $_currentStreak Day Streak! 🔥',
          badge: 'Best: $_bestStreak Days',
          time: _currentTimeString(),
          date: _formatShortDateLabel(DateTime.now()),
        ),
      );
    });

    HapticFeedback.heavyImpact();
    _saveState();
    _showToast('🔥 $_currentStreak-Day Streak Unlocked!');
  }

  /// ==========================================================================
  /// PERSISTENCE (FRESH BY DEFAULT FOR NEW USERS)
  /// ==========================================================================
  Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(raw);
        setState(() {
          _userName = data['userName']?.toString() ?? 'Athlete';
          _currencySymbol = data['currencySymbol']?.toString() ?? '₹';
          _showOnboardingBanner = data['showOnboardingBanner'] as bool? ?? false;

          if (data['enabledModules'] != null) {
            final loadedMods = (data['enabledModules'] as List).map((e) => e.toString()).toList();
            if (loadedMods.isNotEmpty) _enabledModules = loadedMods;
          }

          _lastActiveDate = data['lastActiveDate']?.toString() ?? _todayIsoDate();
          _currentStreak = (data['currentStreak'] as num?)?.toInt() ?? 0;
          _bestStreak = (data['bestStreak'] as num?)?.toInt() ?? 0;
          _lastStreakAwardedDate = data['lastStreakAwardedDate']?.toString() ?? '';
          _dailyGoalStreakThreshold = (data['dailyGoalStreakThreshold'] as num?)?.toInt() ?? 80;
          if (data['streakCompletedDates'] != null) {
            _streakCompletedDates = (data['streakCompletedDates'] as List).map((e) => e.toString()).toSet();
          }

          _waterMl = (data['waterMl'] as num?)?.toInt() ?? 0;
          _waterTarget = (data['waterTarget'] as num?)?.toInt() ?? 2500;
          _stopwatchSeconds = (data['stopwatchSeconds'] as num?)?.toInt() ?? 0;

          _targetCal = (data['targetCal'] as num?)?.toInt() ?? 2400;
          _targetCarb = (data['targetCarb'] as num?)?.toInt() ?? 250;
          _targetProt = (data['targetProt'] as num?)?.toInt() ?? 150;
          _targetFiber = (data['targetFiber'] as num?)?.toInt() ?? 35;
          _targetFat = (data['targetFat'] as num?)?.toInt() ?? 70;

          _age = (data['age'] as num?)?.toInt() ?? 25;
          _heightCm = (data['heightCm'] as num?)?.toInt() ?? 175;
          _weightKg = (data['weightKg'] as num?)?.toInt() ?? 72;
          _gender = data['gender']?.toString() ?? 'male';
          _activityFactor = (data['activityFactor'] as num?)?.toDouble() ?? 1.55;
          _goal = data['goal']?.toString() ?? 'leangain';

          _targetCalCtrl.text = '$_targetCal';
          _targetCarbCtrl.text = '$_targetCarb';
          _targetProtCtrl.text = '$_targetProt';
          _targetFiberCtrl.text = '$_targetFiber';
          _targetFatCtrl.text = '$_targetFat';
          _planAgeCtrl.text = '$_age';
          _planHeightCtrl.text = '$_heightCm';
          _planWeightCtrl.text = '$_weightKg';
          _waterTargetCtrl.text = '$_waterTarget';

          if (data['workouts'] != null) {
            _workouts = (data['workouts'] as List)
                .map((x) => WorkoutSession.fromJson(Map<String, dynamic>.from(x)))
                .toList();
          }
          if (data['tasks'] != null) {
            _tasks = (data['tasks'] as List)
                .map((x) => TaskItem.fromJson(Map<String, dynamic>.from(x)))
                .toList();
          }
          if (data['waterHistory'] != null) {
            _waterHistory = (data['waterHistory'] as List)
                .map((x) => WaterLogItem.fromJson(Map<String, dynamic>.from(x)))
                .toList();
          }
          if (data['foodCatalog'] != null) {
            final loadedFoods = (data['foodCatalog'] as List)
                .map((x) => FoodItemRef.fromJson(Map<String, dynamic>.from(x)))
                .toList();
            if (loadedFoods.isNotEmpty) _foodCatalog = loadedFoods;
          }
          if (!_foodCatalog.any((f) => f.id == _selectedFoodId) && _foodCatalog.isNotEmpty) {
            _selectedFoodId = _foodCatalog.first.id;
          }
          if (data['meals'] != null) {
            _meals = (data['meals'] as List)
                .map((x) => MealEntry.fromJson(Map<String, dynamic>.from(x)))
                .toList();
          }
          if (data['expenseCategories'] != null) {
            final loadedCats = (data['expenseCategories'] as List)
                .map((x) => ExpenseCategoryItem.fromJson(Map<String, dynamic>.from(x)))
                .toList();
            if (loadedCats.isNotEmpty) _expenseCategories = loadedCats;
          }
          if (!_expenseCategories.any((c) => c.name == _selectedExpenseCategory) &&
              _expenseCategories.isNotEmpty) {
            _selectedExpenseCategory = _expenseCategories.first.name;
          }
          if (data['expenses'] != null) {
            _expenses = (data['expenses'] as List)
                .map((x) => ExpenseItem.fromJson(Map<String, dynamic>.from(x)))
                .toList();
          }
          if (data['journals'] != null) {
            _journals = (data['journals'] as List)
                .map((x) => JournalEntry.fromJson(Map<String, dynamic>.from(x)))
                .toList();
          }
          if (data['timeline'] != null) {
            _timeline = (data['timeline'] as List)
                .map((x) => TimelineEvent.fromJson(Map<String, dynamic>.from(x)))
                .toList();
          }
        });
        // Check if day changed since last session
        _checkAndPerformDailyReset();
      }
    } catch (_) {
      // Fresh install starts with empty collections & real DateTime.now()
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode({
        'userName': _userName,
        'currencySymbol': _currencySymbol,
        'showOnboardingBanner': _showOnboardingBanner,
        'enabledModules': _enabledModules,
        'lastActiveDate': _lastActiveDate,
        'currentStreak': _currentStreak,
        'bestStreak': _bestStreak,
        'lastStreakAwardedDate': _lastStreakAwardedDate,
        'dailyGoalStreakThreshold': _dailyGoalStreakThreshold,
        'streakCompletedDates': _streakCompletedDates.toList(),
        'waterMl': _waterMl,
        'waterTarget': _waterTarget,
        'stopwatchSeconds': _stopwatchSeconds,
        'targetCal': _targetCal,
        'targetCarb': _targetCarb,
        'targetProt': _targetProt,
        'targetFiber': _targetFiber,
        'targetFat': _targetFat,
        'age': _age,
        'heightCm': _heightCm,
        'weightKg': _weightKg,
        'gender': _gender,
        'activityFactor': _activityFactor,
        'goal': _goal,
        'workouts': _workouts.map((x) => x.toJson()).toList(),
        'tasks': _tasks.map((x) => x.toJson()).toList(),
        'waterHistory': _waterHistory.map((x) => x.toJson()).toList(),
        'foodCatalog': _foodCatalog.map((x) => x.toJson()).toList(),
        'meals': _meals.map((x) => x.toJson()).toList(),
        'expenseCategories': _expenseCategories.map((x) => x.toJson()).toList(),
        'expenses': _expenses.map((x) => x.toJson()).toList(),
        'journals': _journals.map((x) => x.toJson()).toList(),
        'timeline': _timeline.map((x) => x.toJson()).toList(),
      });
      await prefs.setString(_storageKey, payload);
    } catch (_) {}
  }

  void _factoryResetAllData() {
    setState(() {
      _workouts.clear();
      _tasks.clear();
      _waterMl = 0;
      _waterHistory.clear();
      _meals.clear();
      _expenses.clear();
      _journals.clear();
      _timeline.clear();
      _currentStreak = 0;
      _bestStreak = 0;
      _lastStreakAwardedDate = '';
      _streakCompletedDates.clear();
      _stopwatchSeconds = 0;
      _stopwatchTimer?.cancel();
      _stopwatchTimer = null;
      _foodCatalog = List.from(defaultFoodCatalog);
      _expenseCategories = List.from(defaultExpenseCategories);
      _selectedFoodId = _foodCatalog.first.id;
      _selectedExpenseCategory = _expenseCategories.first.name;
      _showOnboardingBanner = true;
    });
    _saveState();
    _showToast('All user data cleared — fresh state ready');
  }

  void _loadOptionalSampleData() {
    final todayIso = _todayIsoDate();
    final shortDate = _formatShortDateLabel(DateTime.now());
    setState(() {
      _showOnboardingBanner = false;
      _workouts = [
        WorkoutSession(
          id: 'w_demo_1',
          name: '10 Pushups',
          category: 'Strength',
          freqType: '6hours',
          customVal: 6,
          customUnit: 'hours',
          completedToday: 2,
          dailyTargetSets: 4,
          nextDueText: 'Next in 6h',
        ),
        WorkoutSession(
          id: 'w_demo_2',
          name: '50 Bodyweight Squats',
          category: 'Strength',
          freqType: 'daily',
          completedToday: 1,
          dailyTargetSets: 2,
          nextDueText: 'Daily (24h)',
        ),
      ];
      _tasks = [
        TaskItem(
          id: 't_demo_1',
          title: 'Morning Mobility & Hydration',
          priority: 'high',
          repeat: 'daily',
          hasDeadline: true,
          dueDate: todayIso,
          dueTime: '07:30',
          completed: true,
        ),
        TaskItem(
          id: 't_demo_2',
          title: 'Deep Work Architecture Sprint',
          priority: 'high',
          repeat: 'daily',
          hasDeadline: true,
          dueDate: todayIso,
          dueTime: '10:00',
          completed: false,
        ),
        TaskItem(
          id: 't_demo_3',
          title: 'Read 20 Pages of Non-Fiction',
          priority: 'low',
          repeat: 'none',
          hasDeadline: false,
          completed: false,
        ),
      ];
      _waterMl = 1000;
      _waterHistory = [
        WaterLogItem(id: 'wh_demo_1', amount: 500, label: 'Morning Wakeup', time: '07:30 AM'),
        WaterLogItem(id: 'wh_demo_2', amount: 500, label: 'Mid-Morning Glass', time: '10:30 AM'),
      ];
      _meals = [
        MealEntry(
          id: 'm_demo_1',
          name: 'Oatmeal with Protein',
          grams: 120,
          slot: 'Breakfast',
          calories: 408,
          carbs: 58,
          protein: 34,
          fiber: 10,
          fat: 7,
          time: '08:15 AM',
        ),
      ];
      _timeline = [
        TimelineEvent(
          id: 'tl_demo_1',
          category: 'workout',
          title: 'Completed Set: 10 Pushups',
          badge: 'Set #2/4',
          time: '09:00 AM',
          date: shortDate,
        ),
      ];
    });
    _saveState();
    _showToast('Sample data loaded');
  }

  String _currentTimeString() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:$m $ampm';
  }

  void _logTimeline(String category, String title, String badge) {
    HapticFeedback.lightImpact();
    setState(() {
      _timeline.insert(
        0,
        TimelineEvent(
          id: 'tl_${DateTime.now().microsecondsSinceEpoch}',
          category: category,
          title: title,
          badge: badge,
          time: _currentTimeString(),
          date: _formatShortDateLabel(DateTime.now()),
        ),
      );
      _showOnboardingBanner = false;
    });
    _evaluateStreakOnProgress();
    _saveState();
    _showToast(title);
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        backgroundColor: PolarisColors.inputFill,
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  String _formatStopwatch(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _toggleStopwatch() {
    HapticFeedback.selectionClick();
    if (_stopwatchTimer != null) {
      _stopwatchTimer?.cancel();
      setState(() {
        _stopwatchTimer = null;
        _stopwatchLastTick = null;
      });
      _saveState();
    } else {
      _stopwatchLastTick = DateTime.now();
      _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final now = DateTime.now();
        final elapsed = _stopwatchLastTick != null
            ? math.max(1, now.difference(_stopwatchLastTick!).inSeconds)
            : 1;
        _stopwatchLastTick = now;
        setState(() => _stopwatchSeconds += elapsed);
      });
      setState(() {});
    }
  }

  void _resetStopwatch() {
    HapticFeedback.selectionClick();
    _stopwatchTimer?.cancel();
    setState(() {
      _stopwatchTimer = null;
      _stopwatchLastTick = null;
      _stopwatchSeconds = 0;
    });
    _saveState();
  }

  /// ==========================================================================
  /// REAL VOICE RECORDING (`record` + `path_provider`) & PLAYBACK (`audioplayers`)
  /// ==========================================================================
  Future<void> _toggleVoiceRecording() async {
    HapticFeedback.mediumImpact();
    if (!_isRecordingVoice) {
      // Start recording
      try {
        final hasPerm = await _audioRecorder.hasPermission();
        if (hasPerm) {
          final dir = await getApplicationDocumentsDirectory();
          final filePath = '${dir.path}/polaris_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
            path: filePath,
          );
          _currentRecordingPath = filePath;
        } else {
          _currentRecordingPath = null;
          _showToast('Mic permission unavailable — timer mode active');
        }
      } catch (_) {
        _currentRecordingPath = null;
      }

      setState(() {
        _isRecordingVoice = true;
        _voiceSeconds = 0;
      });
      _voiceTimer?.cancel();
      _voiceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _voiceSeconds++);
      });
    } else {
      // Stop recording
      _voiceTimer?.cancel();
      try {
        if (await _audioRecorder.isRecording()) {
          final recordedPath = await _audioRecorder.stop();
          if (recordedPath != null && recordedPath.isNotEmpty) {
            _currentRecordingPath = recordedPath;
          }
        }
      } catch (_) {}
      setState(() => _isRecordingVoice = false);
      _showToast(_currentRecordingPath != null
          ? 'Audio recorded (${_formatStopwatch(_voiceSeconds)}) — tap Save'
          : 'Voice timer stopped — tap Save');
    }
  }

  Future<void> _togglePlayVoiceEntry(JournalEntry j) async {
    HapticFeedback.selectionClick();
    if (_activePlayingVoiceId == j.id) {
      await _audioPlayer.stop();
      setState(() {
        _activePlayingVoiceId = null;
        _audioPosition = Duration.zero;
      });
      return;
    }

    await _audioPlayer.stop();
    if (j.audioFilePath != null && j.audioFilePath!.isNotEmpty) {
      final file = File(j.audioFilePath!);
      if (await file.exists()) {
        setState(() {
          _activePlayingVoiceId = j.id;
          _audioPosition = Duration.zero;
        });
        await _audioPlayer.play(DeviceFileSource(j.audioFilePath!));
        return;
      }
    }

    // Fallback playback indicator if recorded on an emulator without hardware mic file
    setState(() => _activePlayingVoiceId = j.id);
    _showToast('Playing memo: "${j.title}" (${j.duration})');
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _activePlayingVoiceId == j.id) {
        setState(() => _activePlayingVoiceId = null);
      }
    });
  }

  /// ==========================================================================
  /// MODULE CUSTOMIZER & SETTINGS MODAL
  /// ==========================================================================
  void _openModulesAndSettingsSheet() {
    final nameCtrl = TextEditingController(text: _userName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PolarisColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final moduleDefs = [
              {'key': 'workout', 'name': 'Workouts & Conditioning', 'icon': '⚡'},
              {'key': 'todo', 'name': 'Tasks & Visual Schedule', 'icon': '✓'},
              {'key': 'fuel', 'name': 'Nutrition, Diet & Water', 'icon': '🥗'},
              {'key': 'expense', 'name': 'Expense Tracker', 'icon': '💳'},
              {'key': 'journal', 'name': 'Voice & Text Journal', 'icon': '🎙️'},
            ];

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Modules & Settings',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: PolarisColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Profile & Currency
                    const Text(
                      'Profile & Currency',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: PolarisColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _iosTextField(
                            controller: nameCtrl,
                            hint: 'Your Name',
                            onChanged: (val) {
                              setState(() => _userName = val.trim().isEmpty ? 'Athlete' : val.trim());
                              _saveState();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _iosDropdown<String>(
                            value: _currencySymbol,
                            items: const ['₹', '\$', '€', '£', '¥'],
                            onChanged: (v) {
                              setState(() => _currencySymbol = v ?? '₹');
                              setModalState(() {});
                              _saveState();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Active Modules Manager (Add / Remove Modules)
                    const Text(
                      'Active App Modules (Add / Remove)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: PolarisColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Toggle modules to add or remove them from your navigation bar, dashboard, and daily streak calculation.',
                      style: TextStyle(fontSize: 11, color: PolarisColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: PolarisColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: moduleDefs.map((m) {
                          final key = m['key']!;
                          final isEnabled = _enabledModules.contains(key);
                          return SwitchListTile(
                            dense: true,
                            activeColor: PolarisColors.green,
                            title: Text(
                              '${m['icon']}  ${m['name']}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            value: isEnabled,
                            onChanged: (val) {
                              if (!val && _enabledModules.length <= 1) {
                                _showToast('Keep at least 1 module enabled');
                                return;
                              }
                              setState(() {
                                if (val) {
                                  if (!_enabledModules.contains(key)) _enabledModules.add(key);
                                } else {
                                  _enabledModules.remove(key);
                                  if (_activeModuleKey == key) _activeModuleKey = 'home';
                                }
                              });
                              setModalState(() {});
                              _saveState();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Daily Reset & Data Controls
                    const Text(
                      'Daily Rollover & Data Controls',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: PolarisColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _checkAndPerformDailyReset(forceManualReset: true);
                            },
                            icon: const Icon(Icons.wb_sunny_outlined, size: 16, color: PolarisColors.amber),
                            label: const Text(
                              'Start New Day Reset',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: PolarisColors.divider),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _loadOptionalSampleData();
                            },
                            icon: const Icon(Icons.auto_awesome_outlined, size: 16, color: PolarisColors.blue),
                            label: const Text(
                              'Load Demo Data',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: PolarisColors.divider),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _factoryResetAllData();
                        },
                        icon: const Icon(Icons.delete_forever_rounded, size: 18, color: PolarisColors.crimson),
                        label: const Text(
                          'Factory Reset All Data (Fresh User Slate)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PolarisColors.crimson),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ==========================================================================
  /// BUILD SCAFFOLD & DYNAMIC BOTTOM NAVIGATION BAR
  /// ==========================================================================
  @override
  Widget build(BuildContext context) {
    final navItems = <Map<String, dynamic>>[
      {'key': 'home', 'materialIcon': Icons.explore_rounded, 'label': 'Home'},
      if (_enabledModules.contains('workout'))
        {'key': 'workout', 'materialIcon': Icons.bolt_rounded, 'label': 'Workout'},
      if (_enabledModules.contains('todo'))
        {'key': 'todo', 'materialIcon': Icons.check_circle_outline_rounded, 'label': 'Schedule'},
      if (_enabledModules.contains('fuel'))
        {'key': 'fuel', 'materialIcon': Icons.restaurant_rounded, 'label': 'Nutrition'},
      if (_enabledModules.contains('expense'))
        {'key': 'expense', 'materialIcon': Icons.account_balance_wallet_outlined, 'label': 'Expenses'},
      if (_enabledModules.contains('journal'))
        {'key': 'journal', 'materialIcon': Icons.mic_none_rounded, 'label': 'Journal'},
    ];

    if (!navItems.any((item) => item['key'] == _activeModuleKey)) {
      _activeModuleKey = 'home';
    }

    return Scaffold(
      backgroundColor: PolarisColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                _buildTopHeader(),
                Expanded(
                  child: _buildActiveModuleView(),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(navItems),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: PolarisColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.explore_rounded, color: PolarisColors.coral, size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'Polaris',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
            ],
          ),
          Row(
            children: [
              // Live Daily Streak Badge
              GestureDetector(
                onTap: () => _awardStreakForToday(autoTriggered: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _currentStreak > 0
                        ? PolarisColors.coral.withOpacity(0.18)
                        : PolarisColors.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '$_currentStreak d',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _currentStreak > 0 ? PolarisColors.coral : PolarisColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Activity Timeline Shortcut
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (!_enabledModules.contains('journal')) {
                      _enabledModules.add('journal');
                    }
                    _activeModuleKey = 'journal';
                    _journalSubTab = 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: PolarisColors.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Text('Activity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: PolarisColors.green,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_timeline.length}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Modules & Settings Button
              GestureDetector(
                onTap: _openModulesAndSettingsSheet,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: PolarisColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white, size: 17),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveModuleView() {
    switch (_activeModuleKey) {
      case 'workout':
        return _buildWorkoutsTab();
      case 'todo':
        return _buildScheduleAndTasksTab();
      case 'fuel':
        return _buildFuelTab();
      case 'expense':
        return _buildExpensesTab();
      case 'journal':
        return _buildJournalAndTimelineTab();
      case 'home':
      default:
        return _buildSummaryTab();
    }
  }

  Widget _buildBottomNav(List<Map<String, dynamic>> navItems) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121214),
        border: Border(top: BorderSide(color: PolarisColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final key = item['key'] as String;
              final icon = (item['altIcon'] ?? item['materialIcon']) as IconData;
              final label = item['label'] as String;
              final active = _activeModuleKey == key;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activeModuleKey = key);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 22,
                          color: active ? PolarisColors.textPrimary : PolarisColors.textSecondary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            color: active ? PolarisColors.textPrimary : PolarisColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// ==========================================================================
  /// TAB 1: SUMMARY DASHBOARD (WITH STREAK TRACKER, FRESH ONBOARDING & BENTO)
  /// ==========================================================================
  Widget _buildSummaryTab() {
    final now = DateTime.now();
    final todayIso = _todayIsoDate();
    final totalSets = _workouts.fold<int>(0, (a, b) => a + b.completedToday);
    final doneTasks = _tasks.where((t) => t.completed).length;
    final waterPct = (_waterMl / math.max(1, _waterTarget)).clamp(0.0, 1.0);
    final totalCalories = _meals.fold<int>(0, (a, b) => a + b.calories);
    final totalProt = _meals.fold<int>(0, (a, b) => a + b.protein);
    final totalCarb = _meals.fold<int>(0, (a, b) => a + b.carbs);
    final totalFiber = _meals.fold<int>(0, (a, b) => a + b.fiber);
    final totalSpent = _expenses.fold<double>(0, (a, b) => a + b.amount);

    final overallScore = _calculateDailyGoalPercent();
    final isTodayStreakDone = _streakCompletedDates.contains(todayIso);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(
          _formatFullDayHeader(now),
          style: const TextStyle(color: PolarisColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                'Hi, $_userName',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
            ),
            TextButton.icon(
              onPressed: _openModulesAndSettingsSheet,
              icon: const Icon(Icons.widgets_outlined, size: 14, color: PolarisColors.blue),
              label: const Text(
                'Modules',
                style: TextStyle(color: PolarisColors.blue, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // First-Run Fresh State Welcome Card
        if (_showOnboardingBanner &&
            _workouts.isEmpty &&
            _tasks.isEmpty &&
            _meals.isEmpty &&
            _waterMl == 0) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PolarisColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PolarisColors.coral.withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Welcome to Your Fresh Polaris Space',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _showOnboardingBanner = false);
                        _saveState();
                      },
                      child: const Icon(Icons.close_rounded, size: 16, color: PolarisColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your tracker starts 100% fresh with zero hardcoded clutter. Daily workouts, water, meals, and repeating tasks automatically reset at midnight.',
                  style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _pillButton(
                        label: 'Configure Profile & Modules',
                        bg: Colors.white,
                        fg: Colors.black,
                        onTap: _openModulesAndSettingsSheet,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _loadOptionalSampleData,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: PolarisColors.divider),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Demo Data',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PolarisColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Daily Streak & 7-Day Consistency Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PolarisColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: PolarisColors.coral.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text('🔥', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_currentStreak Day Streak',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Best Streak: $_bestStreak days • Auto-unlocks at $_dailyGoalStreakThreshold%',
                            style: const TextStyle(fontSize: 11, color: PolarisColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _awardStreakForToday(autoTriggered: false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isTodayStreakDone ? PolarisColors.green.withOpacity(0.2) : PolarisColors.inputFill,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isTodayStreakDone ? '✓ Locked In' : 'Claim Streak',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isTodayStreakDone ? PolarisColors.green : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Last 7 Days Consistency Strip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (idx) {
                  final dayDt = now.subtract(Duration(days: 6 - idx));
                  final dIso = _formatIsoDate(dayDt);
                  final isDone = _streakCompletedDates.contains(dIso);
                  final isToday = dIso == todayIso;
                  const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  return Column(
                    children: [
                      Text(
                        dayLetters[dayDt.weekday - 1],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isToday ? Colors.white : PolarisColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? PolarisColors.coral
                              : (isToday ? PolarisColors.inputFill : PolarisColors.surfaceElevated),
                          border: isToday && !isDone
                              ? Border.all(color: PolarisColors.coral, width: 1.5)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isDone ? '✓' : '${dayDt.day}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isDone ? Colors.white : PolarisColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Apple Fitness Style Daily Goal Ring Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: PolarisColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 108,
                height: 108,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(108, 108),
                      painter: _ActivityRingPainter(progress: overallScore / 100.0),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$overallScore%',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        const Text(
                          'Daily Goal',
                          style: TextStyle(fontSize: 11, color: PolarisColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _metricRow('Active Burn', '${totalSets * 25} KCAL', PolarisColors.crimson),
                    const SizedBox(height: 10),
                    _metricRow('Session Timer', _formatStopwatch(_stopwatchSeconds), PolarisColors.green),
                    const SizedBox(height: 10),
                    _metricRow('Hydration', '${(waterPct * 100).round()}% ($_waterMl ml)', PolarisColors.blue),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Dynamic Module Bento Cards (Only renders enabled modules)
        if (_enabledModules.contains('workout') || _enabledModules.contains('fuel'))
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_enabledModules.contains('workout'))
                  Expanded(
                    child: _buildBentoCard(
                      icon: '⚡',
                      title: 'Workouts',
                      accent: PolarisColors.coral,
                      trailing: '$totalSets Sets',
                      onTap: () => setState(() => _activeModuleKey = 'workout'),
                      body: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _workouts.isNotEmpty ? _workouts.first.name : 'No sessions yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _workouts.isNotEmpty ? _workouts.first.freqLabel : 'Tap to add exercise',
                            style: const TextStyle(fontSize: 12, color: PolarisColors.textSecondary),
                          ),
                        ],
                      ),
                      footer: _pillButton(
                        label: _workouts.isNotEmpty ? 'Log Set' : '+ Add Workout',
                        bg: PolarisColors.coral,
                        fg: Colors.white,
                        onTap: () {
                          if (_workouts.isNotEmpty) {
                            _incrementWorkoutSet(_workouts.first);
                          } else {
                            setState(() => _activeModuleKey = 'workout');
                          }
                        },
                      ),
                    ),
                  ),
                if (_enabledModules.contains('workout') && _enabledModules.contains('fuel'))
                  const SizedBox(width: 12),
                if (_enabledModules.contains('fuel'))
                  Expanded(
                    child: _buildBentoCard(
                      icon: '💧',
                      title: 'Water',
                      accent: PolarisColors.blue,
                      trailing: '${(_waterMl / 1000).toStringAsFixed(1)}L',
                      onTap: () => setState(() {
                        _activeModuleKey = 'fuel';
                        _fuelSubTab = 2;
                      }),
                      body: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_waterMl / $_waterTarget ml',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: waterPct,
                              minHeight: 6,
                              backgroundColor: PolarisColors.inputFill,
                              valueColor: const AlwaysStoppedAnimation(PolarisColors.blue),
                            ),
                          ),
                        ],
                      ),
                      footer: Row(
                        children: [
                          Expanded(
                            child: _pillButton(
                              label: '+100',
                              bg: PolarisColors.inputFill,
                              fg: Colors.white,
                              onTap: () => _addWater(100, 'Quick Hydrate (+100ml)'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _pillButton(
                              label: '+250',
                              bg: PolarisColors.blue,
                              fg: Colors.white,
                              onTap: () => _addWater(250, 'Glass of Water (+250ml)'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (_enabledModules.contains('workout') || _enabledModules.contains('fuel'))
          const SizedBox(height: 12),

        if (_enabledModules.contains('fuel') || _enabledModules.contains('todo') || _enabledModules.contains('expense'))
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_enabledModules.contains('fuel'))
                  Expanded(
                    child: _buildBentoCard(
                      icon: '🥗',
                      title: 'Nutrition',
                      accent: PolarisColors.green,
                      trailing: '›',
                      onTap: () => setState(() {
                        _activeModuleKey = 'fuel';
                        _fuelSubTab = 0;
                      }),
                      body: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalCalories / $_targetCal kcal',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          _miniStatRow('Protein', '$totalProt/${_targetProt}g'),
                          const SizedBox(height: 3),
                          _miniStatRow('Carbs', '$totalCarb/${_targetCarb}g'),
                          const SizedBox(height: 3),
                          _miniStatRow('Fiber', '$totalFiber/${_targetFiber}g'),
                        ],
                      ),
                      footer: const SizedBox.shrink(),
                    ),
                  ),
                if (_enabledModules.contains('fuel') &&
                    (_enabledModules.contains('todo') || _enabledModules.contains('expense')))
                  const SizedBox(width: 12),
                if (_enabledModules.contains('todo') || _enabledModules.contains('expense'))
                  Expanded(
                    child: _buildBentoCard(
                      icon: '✓',
                      title: 'Tasks & Spend',
                      accent: PolarisColors.amber,
                      trailing: '$doneTasks/${_tasks.length}',
                      onTap: () => setState(() {
                        _activeModuleKey = _enabledModules.contains('todo') ? 'todo' : 'expense';
                      }),
                      body: const Text(
                        'Daily tasks & expenses',
                        style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary),
                      ),
                      footer: GestureDetector(
                        onTap: () {
                          if (_enabledModules.contains('expense')) {
                            setState(() => _activeModuleKey = 'expense');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.only(top: 10),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: PolarisColors.divider, width: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Spent',
                                style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '$_currencySymbol${totalSpent.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

        if (_enabledModules.contains('todo')) ...[
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Today\'s Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => setState(() {
                  _activeModuleKey = 'todo';
                  _todoScheduleSubTab = 1;
                }),
                child: const Text(
                  'Full Schedule →',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PolarisColors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: PolarisColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: _tasks.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(
                      child: Text(
                        'No tasks yet. Tap Schedule to add your first task.',
                        style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary),
                      ),
                    ),
                  )
                : Column(
                    children: _tasks.take(4).map((t) => _buildTaskRow(t, showDelete: false)).toList(),
                  ),
          ),
        ],
      ],
    );
  }

  Widget _metricRow(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.15)),
      ],
    );
  }

  Widget _miniStatRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: PolarisColors.textSecondary)),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildBentoCard({
    required String icon,
    required String title,
    required Color accent,
    required String trailing,
    required VoidCallback onTap,
    required Widget body,
    required Widget footer,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PolarisColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(icon, style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          title,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent),
                        ),
                      ],
                    ),
                    Text(
                      trailing,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PolarisColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                body,
              ],
            ),
            const SizedBox(height: 12),
            footer,
          ],
        ),
      ),
    );
  }

  /// ==========================================================================
  /// TAB 2: WORKOUTS (ADD, EDIT, +1 SET, -1 SET DECREMENT, DELETE)
  /// ==========================================================================
  void _incrementWorkoutSet(WorkoutSession w) {
    setState(() {
      w.completedToday += 1;
      if (w.freqType == '6hours') {
        w.nextDueText = 'Next in 6h';
      } else if (w.freqType == 'daily') {
        w.nextDueText = w.completedToday >= w.dailyTargetSets ? 'Daily Goal Met ✓' : 'In Progress';
      } else {
        w.nextDueText = 'Next in ${w.customVal} ${w.customUnit}';
      }
    });
    _logTimeline('workout', 'Completed ${w.name}', 'Set #${w.completedToday}/${w.dailyTargetSets} • ${w.freqLabel}');
  }

  void _decrementWorkoutSet(WorkoutSession w) {
    if (w.completedToday <= 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      w.completedToday -= 1;
      if (w.completedToday == 0) w.nextDueText = 'Due Today';
    });
    _saveState();
    _showToast('Decremented ${w.name} to ${w.completedToday} sets');
  }

  void _openEditWorkoutModal(WorkoutSession w) {
    final editNameCtrl = TextEditingController(text: w.name);
    final editTargetSetsCtrl = TextEditingController(text: '${w.dailyTargetSets}');
    final editCustomValCtrl = TextEditingController(text: '${w.customVal}');
    String editCategory = w.category;
    String editFreq = w.freqType;
    String editUnit = w.customUnit;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PolarisColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Training Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _iosTextField(controller: editNameCtrl, hint: 'Exercise Name'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _iosDropdown<String>(
                      value: editCategory,
                      items: const ['Strength', 'Core', 'Cardio', 'Mobility'],
                      onChanged: (v) => setModalState(() => editCategory = v ?? 'Strength'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _iosTextField(
                      controller: editTargetSetsCtrl,
                      hint: 'Daily Target Sets',
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _iosDropdown<String>(
                value: editFreq,
                items: const ['daily', '6hours', 'custom'],
                itemLabels: const {
                  'daily': 'Daily (24h)',
                  '6hours': 'Every 6 Hours',
                  'custom': 'Custom Interval',
                },
                onChanged: (v) => setModalState(() => editFreq = v ?? 'daily'),
              ),
              if (editFreq == 'custom') ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _iosTextField(controller: editCustomValCtrl, hint: 'Interval', isNumber: true),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _iosDropdown<String>(
                        value: editUnit,
                        items: const ['hours', 'days', 'minutes'],
                        onChanged: (v) => setModalState(() => editUnit = v ?? 'hours'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _pillButton(
                  label: 'Save Changes',
                  bg: PolarisColors.coral,
                  fg: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onTap: () {
                    setState(() {
                      w.name = editNameCtrl.text.trim().isEmpty ? w.name : editNameCtrl.text.trim();
                      w.category = editCategory;
                      w.freqType = editFreq;
                      w.dailyTargetSets = (int.tryParse(editTargetSetsCtrl.text) ?? 3).clamp(1, 50);
                      w.customVal = (int.tryParse(editCustomValCtrl.text) ?? 4).clamp(1, 168);
                      w.customUnit = editUnit;
                    });
                    _saveState();
                    Navigator.pop(ctx);
                    _showToast('Updated ${w.name}');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutsTab() {
    final totalSets = _workouts.fold<int>(0, (a, w) => a + w.completedToday);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conditioning • Resets Daily', style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary, fontWeight: FontWeight.w600)),
                Text('Workouts', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: PolarisColors.coral.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$totalSets Sets Today',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: PolarisColors.coral),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Active Stopwatch Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active Session Timer', style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    _formatStopwatch(_stopwatchSeconds),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Row(
                children: [
                  _pillButton(
                    label: _stopwatchTimer != null ? 'Pause' : 'Start',
                    bg: PolarisColors.green,
                    fg: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    onTap: _toggleStopwatch,
                  ),
                  const SizedBox(width: 8),
                  _pillButton(
                    label: 'Reset',
                    bg: PolarisColors.inputFill,
                    fg: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    onTap: _resetStopwatch,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // New Training Session Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Training Session', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _iosTextField(controller: _workoutNameCtrl, hint: 'Exercise (e.g. 10 Pushups)'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _iosDropdown<String>(
                      value: _workoutCategory,
                      items: const ['Strength', 'Core', 'Cardio', 'Mobility'],
                      onChanged: (v) => setState(() => _workoutCategory = v ?? 'Strength'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        _freqChip('Daily', 'daily'),
                        const SizedBox(width: 6),
                        _freqChip('6 Hours', '6hours'),
                        const SizedBox(width: 6),
                        _freqChip('Custom', 'custom'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 85,
                    child: _iosTextField(
                      controller: _workoutTargetSetsCtrl,
                      hint: 'Goal Sets',
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              if (_workoutFreq == 'custom') ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _iosTextField(
                        controller: _workoutCustomValCtrl,
                        hint: 'Interval (e.g. 4)',
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _iosDropdown<String>(
                        value: _workoutCustomUnit,
                        items: const ['hours', 'days', 'minutes'],
                        itemLabels: const {'hours': 'Hours', 'days': 'Days', 'minutes': 'Minutes'},
                        onChanged: (v) => setState(() => _workoutCustomUnit = v ?? 'hours'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _pillButton(
                  label: '+ Add Training Session',
                  bg: PolarisColors.coral,
                  fg: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  onTap: () {
                    final text = _workoutNameCtrl.text.trim();
                    if (text.isEmpty) {
                      _showToast('Enter an exercise name');
                      return;
                    }
                    final customVal = (int.tryParse(_workoutCustomValCtrl.text) ?? 4).clamp(1, 168);
                    final targetSets = (int.tryParse(_workoutTargetSetsCtrl.text) ?? 3).clamp(1, 50);
                    final w = WorkoutSession(
                      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
                      name: text,
                      category: _workoutCategory,
                      freqType: _workoutFreq,
                      customVal: customVal,
                      customUnit: _workoutCustomUnit,
                      completedToday: 0,
                      dailyTargetSets: targetSets,
                      nextDueText: 'Due Now',
                    );
                    setState(() {
                      _workouts.insert(0, w);
                      _workoutNameCtrl.clear();
                    });
                    _logTimeline('workout', 'Added Workout: ${w.name}', w.freqLabel);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_workouts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
            child: const Center(
              child: Text(
                'No workout sessions added yet. Add your first training drill above.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary),
              ),
            ),
          )
        else
          ..._workouts.map(
            (w) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: PolarisColors.coral.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('⚡', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openEditWorkoutModal(w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  w.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit_outlined, size: 13, color: PolarisColors.textSecondary),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${w.category} • ${w.freqLabel} • ${w.completedToday}/${w.dailyTargetSets} sets',
                            style: const TextStyle(fontSize: 12, color: PolarisColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (w.completedToday > 0) ...[
                    IconButton(
                      onPressed: () => _decrementWorkoutSet(w),
                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: PolarisColors.textSecondary),
                      tooltip: 'Undo 1 Set',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                  _pillButton(
                    label: '+ Set',
                    bg: PolarisColors.coral,
                    fg: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onTap: () => _incrementWorkoutSet(w),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _workouts.removeWhere((item) => item.id == w.id));
                      _saveState();
                      _showToast('Removed ${w.name}');
                    },
                    icon: const Icon(Icons.close_rounded, size: 18, color: PolarisColors.textSecondary),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _freqChip(String label, String val) {
    final selected = _workoutFreq == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _workoutFreq = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : PolarisColors.inputFill,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black : PolarisColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// ==========================================================================
  /// TAB 3: TASKS & DYNAMIC VISUAL SCHEDULE (ANY MONTH/YEAR + EDIT/DELETE)
  /// ==========================================================================
  bool _doesTaskOccurOnDate(TaskItem t, String targetDateStr) {
    if (!t.hasDeadline || t.dueDate.isEmpty) return false;
    if (t.dueDate == targetDateStr) return true;
    final start = DateTime.tryParse('${t.dueDate}T00:00:00');
    final target = DateTime.tryParse('${targetDateStr}T00:00:00');
    if (start == null || target == null || target.isBefore(start)) return false;
    final diffDays = target.difference(start).inDays;
    if (t.repeat == 'daily') return true;
    if (t.repeat == 'weekly') return diffDays % 7 == 0;
    if (t.repeat == 'custom') {
      final match = RegExp(r'(\d+)').firstMatch(t.customRepeat);
      final step = match != null ? math.max(1, int.tryParse(match.group(1)!) ?? 2) : 2;
      return diffDays % step == 0;
    }
    return false;
  }

  Future<void> _pickTaskDate() async {
    final initial = DateTime.tryParse(_taskDraftDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2032, 12, 31),
    );
    if (picked != null) {
      setState(() => _taskDraftDate = _formatIsoDate(picked));
    }
  }

  Future<void> _pickTaskTime() async {
    final parts = _taskDraftTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 30) : 30,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      setState(() => _taskDraftTime = '$hh:$mm');
    }
  }

  Widget _buildScheduleAndTasksTab() {
    final selDt = DateTime.tryParse('${_selectedDate}T00:00:00') ?? DateTime.now();
    final scheduledForDay = _tasks
        .where((t) => _doesTaskOccurOnDate(t, _selectedDate))
        .toList()
      ..sort((a, b) => a.dueTime.compareTo(b.dueTime));
    final noDeadlineTasks = _tasks.where((t) => !t.hasDeadline).toList();

    List<TaskItem> filteredTasks = List.from(_tasks);
    if (_todoFilter == 'active') filteredTasks = filteredTasks.where((t) => !t.completed).toList();
    if (_todoFilter == 'repeating') filteredTasks = filteredTasks.where((t) => t.repeat != 'none').toList();
    if (_todoFilter == 'nodeadline') filteredTasks = filteredTasks.where((t) => !t.hasDeadline).toList();
    if (_todoFilter == 'done') filteredTasks = filteredTasks.where((t) => t.completed).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _todoScheduleSubTab == 0 ? 'Tasks' : 'Schedule',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  _segTabButton('Tasks', _todoScheduleSubTab == 0, () => setState(() => _todoScheduleSubTab = 0)),
                  _segTabButton('Schedule', _todoScheduleSubTab == 1, () => setState(() => _todoScheduleSubTab = 1)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_todoScheduleSubTab == 0) ...[
          // Add Task Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                _iosTextField(controller: _taskTitleCtrl, hint: 'New task...'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _iosDropdown<String>(
                        value: _taskRepeat,
                        items: const ['none', 'daily', 'weekly', 'custom'],
                        itemLabels: const {
                          'none': 'One-Time',
                          'daily': 'Repeat Daily',
                          'weekly': 'Repeat Weekly',
                          'custom': 'Custom Repeat',
                        },
                        onChanged: (v) => setState(() => _taskRepeat = v ?? 'none'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _iosDropdown<String>(
                        value: _taskPriority,
                        items: const ['high', 'medium', 'low'],
                        itemLabels: const {
                          'high': 'High Priority',
                          'medium': 'Medium Priority',
                          'low': 'Low Priority',
                        },
                        onChanged: (v) => setState(() => _taskPriority = v ?? 'medium'),
                      ),
                    ),
                  ],
                ),
                if (_taskRepeat == 'custom') ...[
                  const SizedBox(height: 10),
                  _iosTextField(
                    controller: _taskCustomRepeatCtrl,
                    hint: 'Custom repeat (e.g. Every 2 days)',
                  ),
                ],
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Set Deadline', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: _taskHasDeadline,
                  activeColor: PolarisColors.blue,
                  onChanged: (v) => setState(() => _taskHasDeadline = v),
                ),
                if (_taskHasDeadline) ...[
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickTaskDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: PolarisColors.inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_taskDraftDate, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                const Icon(Icons.calendar_today_rounded, size: 15, color: PolarisColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickTaskTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: PolarisColors.inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_taskDraftTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                const Icon(Icons.access_time_rounded, size: 15, color: PolarisColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: _pillButton(
                    label: '+ Add Task to Path',
                    bg: Colors.white,
                    fg: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    onTap: () {
                      final text = _taskTitleCtrl.text.trim();
                      if (text.isEmpty) {
                        _showToast('Enter a task title');
                        return;
                      }
                      final t = TaskItem(
                        id: 't_${DateTime.now().millisecondsSinceEpoch}',
                        title: text,
                        priority: _taskPriority,
                        repeat: _taskRepeat,
                        customRepeat: _taskRepeat == 'custom' ? _taskCustomRepeatCtrl.text.trim() : '',
                        hasDeadline: _taskHasDeadline,
                        dueDate: _taskHasDeadline ? _taskDraftDate : '',
                        dueTime: _taskHasDeadline ? _taskDraftTime : '',
                      );
                      setState(() {
                        _tasks.insert(0, t);
                        _taskTitleCtrl.clear();
                      });
                      _logTimeline(
                        'todo',
                        'Created Task: ${t.title}',
                        t.hasDeadline ? 'Due ${t.dueDate}' : 'No Deadline',
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Task Filter Chips + Clear Completed
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', _todoFilter == 'all', () => setState(() => _todoFilter = 'all')),
                _filterChip('Active', _todoFilter == 'active', () => setState(() => _todoFilter = 'active')),
                _filterChip('Repeating', _todoFilter == 'repeating', () => setState(() => _todoFilter = 'repeating')),
                _filterChip('No Deadline', _todoFilter == 'nodeadline', () => setState(() => _todoFilter = 'nodeadline')),
                _filterChip('Completed', _todoFilter == 'done', () => setState(() => _todoFilter = 'done')),
                if (_tasks.any((t) => t.completed))
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _tasks.removeWhere((t) => t.completed));
                        _saveState();
                        _showToast('Cleared completed tasks');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: PolarisColors.crimson.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Clear Done',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PolarisColors.crimson),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
            child: filteredTasks.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('No tasks in this view.', style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary)),
                    ),
                  )
                : Column(
                    children: filteredTasks.map((t) => _buildTaskRow(t, showDelete: true)).toList(),
                  ),
          ),
        ] else ...[
          // VISUAL SCHEDULE SUB-TAB (Dynamic Month/Year + 7-Day Strip + Hourly + Backlog)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(child: _segTabButton('All Visuals', _scheduleViewMode == 'all', () => setState(() => _scheduleViewMode = 'all'))),
                Expanded(child: _segTabButton('Month Grid', _scheduleViewMode == 'month', () => setState(() => _scheduleViewMode = 'month'))),
                Expanded(child: _segTabButton('Day & Hourly', _scheduleViewMode == 'time', () => setState(() => _scheduleViewMode = 'time'))),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Dynamic 7-Day Strip centered around _selectedDate
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (idx) {
                final dayDt = selDt.subtract(Duration(days: 3 - idx));
                final dStr = _formatIsoDate(dayDt);
                final selected = dStr == _selectedDate;
                final hasTask = _tasks.any((t) => _doesTaskOccurOnDate(t, dStr));
                const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedDate = dStr;
                    _calendarMonth = DateTime(dayDt.year, dayDt.month, 1);
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? PolarisColors.coral : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          dayNames[dayDt.weekday - 1],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : PolarisColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dayDt.day}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasTask
                                ? (selected ? Colors.white : PolarisColors.coral)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // Dynamic Any-Month Calendar Grid
          if (_scheduleViewMode == 'all' || _scheduleViewMode == 'month') ...[
            _buildDynamicMonthlyCalendarGrid(),
            const SizedBox(height: 18),
          ],

          // Hourly Timeline for Selected Date
          if (_scheduleViewMode == 'all' || _scheduleViewMode == 'time') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hourly Timeline (${_formatShortDateLabel(selDt)})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${scheduledForDay.length} scheduled',
                  style: const TextStyle(fontSize: 12, color: PolarisColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
              child: scheduledForDay.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No scheduled tasks for this date.',
                          style: TextStyle(color: PolarisColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    )
                  : Column(
                      children: scheduledForDay.map((t) => _buildTaskRow(t, showDelete: false)).toList(),
                    ),
            ),
            const SizedBox(height: 20),
          ],

          // Unscheduled Tasks Pinned at Bottom
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No Deadline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(
                    'Unscheduled tasks pinned at the bottom',
                    style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary),
                  ),
                ],
              ),
              Text(
                '${noDeadlineTasks.length} items',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PolarisColors.amber),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
            child: noDeadlineTasks.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'All tasks are scheduled.',
                        style: TextStyle(color: PolarisColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  )
                : Column(
                    children: noDeadlineTasks
                        .map((t) => _buildTaskRow(t, showScheduleAction: true, showDelete: true))
                        .toList(),
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildDynamicMonthlyCalendarGrid() {
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingEmptyCells = firstDayOfMonth.weekday % 7; // Sunday = 0

    final cells = <Widget>[];
    for (int pad = 0; pad < leadingEmptyCells; pad++) {
      cells.add(const SizedBox(height: 36));
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final dStr = _formatIsoDate(DateTime(year, month, d));
      final isSelected = dStr == _selectedDate;
      final isToday = dStr == _todayIsoDate();
      final hasTask = _tasks.any((t) => _doesTaskOccurOnDate(t, dStr));
      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDate = dStr),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: isSelected
                  ? PolarisColors.coral
                  : (isToday ? PolarisColors.inputFill : Colors.transparent),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$d',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : PolarisColors.textPrimary,
                  ),
                ),
                if (hasTask)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.white : PolarisColors.blue,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() {
                  _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1);
                }),
                icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                visualDensity: VisualDensity.compact,
              ),
              GestureDetector(
                onTap: () {
                  final now = DateTime.now();
                  setState(() {
                    _calendarMonth = DateTime(now.year, now.month, 1);
                    _selectedDate = _formatIsoDate(now);
                  });
                },
                child: Text(
                  _formatMonthYearHeader(_calendarMonth),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1);
                }),
                icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('S', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PolarisColors.textSecondary)),
              Text('M', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PolarisColors.textSecondary)),
              Text('T', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PolarisColors.textSecondary)),
              Text('W', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PolarisColors.textSecondary)),
              Text('T', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PolarisColors.textSecondary)),
              Text('F', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PolarisColors.textSecondary)),
              Text('S', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PolarisColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: cells,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(TaskItem t, {bool showScheduleAction = false, bool showDelete = false}) {
    final prioColor = t.priority == 'high'
        ? PolarisColors.crimson
        : (t.priority == 'low' ? PolarisColors.blue : PolarisColors.amber);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PolarisColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() => t.completed = !t.completed);
              if (t.completed) {
                _logTimeline('todo', 'Completed Task: ${t.title}', t.repeatLabel);
              } else {
                _saveState();
              }
            },
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: t.completed ? PolarisColors.green : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: t.completed ? PolarisColors.green : PolarisColors.textSecondary,
                  width: 2,
                ),
              ),
              child: t.completed ? const Icon(Icons.check, size: 14, color: Colors.black) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.completed ? PolarisColors.textSecondary : PolarisColors.textPrimary,
                    decoration: t.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: prioColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '${t.repeatLabel} • ${t.hasDeadline ? "${t.dueDate} ${t.dueTime}" : "No Deadline"}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: PolarisColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showScheduleAction)
            _pillButton(
              label: 'Schedule Today',
              bg: PolarisColors.inputFill,
              fg: PolarisColors.amber,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              onTap: () {
                setState(() {
                  t.hasDeadline = true;
                  t.dueDate = _selectedDate;
                  t.dueTime = '16:00';
                });
                _logTimeline('todo', 'Scheduled Task: ${t.title}', '$_selectedDate 16:00');
              },
            ),
          if (showDelete) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                setState(() => _tasks.removeWhere((item) => item.id == t.id));
                _saveState();
                _showToast('Task deleted');
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: PolarisColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ==========================================================================
  /// TAB 4: NUTRITION, CUSTOM FOOD CATALOG, DIET PLANNER & WATER
  /// ==========================================================================
  void _addWater(int delta, String label) {
    final prev = _waterMl;
    final nextVal = (_waterMl + delta).clamp(0, 15000);
    final actualDelta = nextVal - prev;
    if (actualDelta == 0) return;

    setState(() {
      _waterMl = nextVal;
      if (actualDelta > 0) {
        _waterHistory.insert(
          0,
          WaterLogItem(
            id: 'wh_${DateTime.now().millisecondsSinceEpoch}',
            amount: actualDelta,
            label: label,
            time: _currentTimeString(),
          ),
        );
      }
    });

    if (actualDelta > 0) {
      _logTimeline('water', 'Drank Water (+${actualDelta}ml)', '$_waterMl / $_waterTarget ml');
    } else {
      _saveState();
      _showToast('Water adjusted (${actualDelta}ml)');
    }
  }

  Map<String, int> _calculateActiveFoodMacros() {
    final grams = (int.tryParse(_mealQtyCtrl.text) ?? 100).clamp(5, 3000);
    final ratio = grams / 100.0;

    if (_isCustomFoodMode) {
      final cal100 = (int.tryParse(_customFoodCalCtrl.text) ?? 200).clamp(0, 900);
      final carb100 = (int.tryParse(_customFoodCarbCtrl.text) ?? 20).clamp(0, 100);
      final prot100 = (int.tryParse(_customFoodProtCtrl.text) ?? 25).clamp(0, 100);
      final fib100 = (int.tryParse(_customFoodFiberCtrl.text) ?? 4).clamp(0, 100);
      final fat100 = math.max(0, ((cal100 - (carb100 * 4 + prot100 * 4)) / 9).round());
      return {
        'grams': grams,
        'cal': (cal100 * ratio).round(),
        'carb': (carb100 * ratio).round(),
        'prot': (prot100 * ratio).round(),
        'fiber': (fib100 * ratio).round(),
        'fat': (fat100 * ratio).round(),
      };
    } else {
      final selectedFood = _foodCatalog.firstWhere(
        (f) => f.id == _selectedFoodId,
        orElse: () => _foodCatalog.isNotEmpty ? _foodCatalog.first : defaultFoodCatalog.first,
      );
      return {
        'grams': grams,
        'cal': (selectedFood.cal * ratio).round(),
        'carb': (selectedFood.carb * ratio).round(),
        'prot': (selectedFood.prot * ratio).round(),
        'fiber': (selectedFood.fiber * ratio).round(),
        'fat': (selectedFood.fat * ratio).round(),
      };
    }
  }

  Map<String, int> _computeMifflinDietPlan() {
    final s = _gender == 'male' ? 5 : -161;
    final bmr = (10 * _weightKg + 6.25 * _heightCm - 5 * _age + s).round();
    final tdee = (bmr * _activityFactor).round();

    int delta = 0;
    if (_goal == 'loss') delta = -500;
    if (_goal == 'leancut') delta = -250;
    if (_goal == 'leangain') delta = 300;
    if (_goal == 'gain') delta = 500;

    final recCal = math.max(1200, tdee + delta);
    final recProt = (_weightKg * 2.2).round();
    final recFat = ((recCal * 0.26) / 9).round();
    final recCarb = math.max(60, ((recCal - (recProt * 4 + recFat * 9)) / 4).round());
    final recFiber = ((recCal / 1000.0) * 14).round();
    final recWater = (_weightKg * 40).round();

    return {
      'bmr': bmr,
      'tdee': tdee,
      'cal': recCal,
      'carb': recCarb,
      'prot': recProt,
      'fiber': recFiber,
      'fat': recFat,
      'water': recWater,
    };
  }

  Widget _buildFuelTab() {
    if (!_foodCatalog.any((f) => f.id == _selectedFoodId) && _foodCatalog.isNotEmpty) {
      _selectedFoodId = _foodCatalog.first.id;
    }

    final totalCal = _meals.fold<int>(0, (a, b) => a + b.calories);
    final totalProt = _meals.fold<int>(0, (a, b) => a + b.protein);
    final totalCarb = _meals.fold<int>(0, (a, b) => a + b.carbs);
    final totalFiber = _meals.fold<int>(0, (a, b) => a + b.fiber);
    final totalFat = _meals.fold<int>(0, (a, b) => a + b.fat);
    final livePreview = _calculateActiveFoodMacros();
    final dietPlan = _computeMifflinDietPlan();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const Text('Daily Fuel • Resets at Midnight', style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary, fontWeight: FontWeight.w600)),
        const Text('Nutrition', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(child: _segTabButton('🥗 Meals', _fuelSubTab == 0, () => setState(() => _fuelSubTab = 0))),
              Expanded(child: _segTabButton('⚡ Diet Plan', _fuelSubTab == 1, () => setState(() => _fuelSubTab = 1))),
              Expanded(child: _segTabButton('💧 Water', _fuelSubTab == 2, () => setState(() => _fuelSubTab = 2))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_fuelSubTab == 0) ...[
          // Macro Overview Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Calories Consumed Today', style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          '$totalCal / $_targetCal kcal',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    _pillButton(
                      label: _showMacroTargetEditor ? 'Close' : 'Edit Targets',
                      bg: PolarisColors.inputFill,
                      fg: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      onTap: () => setState(() => _showMacroTargetEditor = !_showMacroTargetEditor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (totalCal / math.max(1, _targetCal)).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: PolarisColors.inputFill,
                    valueColor: const AlwaysStoppedAnimation(PolarisColors.green),
                  ),
                ),
                if (_showMacroTargetEditor) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: PolarisColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Edit Daily Macro Targets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _labeledNumberInput('Calories', _targetCalCtrl)),
                            const SizedBox(width: 8),
                            Expanded(child: _labeledNumberInput('Carbs (g)', _targetCarbCtrl)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _labeledNumberInput('Protein (g)', _targetProtCtrl)),
                            const SizedBox(width: 8),
                            Expanded(child: _labeledNumberInput('Fiber (g)', _targetFiberCtrl)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _labeledNumberInput('Fats (g)', _targetFatCtrl),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: _pillButton(
                            label: 'Save Macro Targets',
                            bg: Colors.white,
                            fg: Colors.black,
                            onTap: () {
                              setState(() {
                                _targetCal = (int.tryParse(_targetCalCtrl.text) ?? 2400).clamp(800, 10000);
                                _targetCarb = (int.tryParse(_targetCarbCtrl.text) ?? 250).clamp(20, 1200);
                                _targetProt = (int.tryParse(_targetProtCtrl.text) ?? 150).clamp(20, 600);
                                _targetFiber = (int.tryParse(_targetFiberCtrl.text) ?? 35).clamp(10, 150);
                                _targetFat = (int.tryParse(_targetFatCtrl.text) ?? 70).clamp(15, 400);
                                _showMacroTargetEditor = false;
                              });
                              _logTimeline('meal', 'Updated Macro Targets', '$_targetCal kcal');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _macroBox('Protein', '$totalProt/${_targetProt}g', totalProt / math.max(1, _targetProt), PolarisColors.green)),
                    const SizedBox(width: 10),
                    Expanded(child: _macroBox('Carbs', '$totalCarb/${_targetCarb}g', totalCarb / math.max(1, _targetCarb), PolarisColors.blue)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _macroBox('Fiber', '$totalFiber/${_targetFiber}g', totalFiber / math.max(1, _targetFiber), PolarisColors.amber)),
                    const SizedBox(width: 10),
                    Expanded(child: _macroBox('Fats', '$totalFat/${_targetFat}g', totalFat / math.max(1, _targetFat), PolarisColors.crimson)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Food Calculator & Custom Food Catalog Manager
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Log Food Item', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    GestureDetector(
                      onTap: () => setState(() => _isCustomFoodMode = !_isCustomFoodMode),
                      child: Text(
                        _isCustomFoodMode ? '← Preset Catalog' : '+ Custom Food',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PolarisColors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (!_isCustomFoodMode)
                  Row(
                    children: [
                      Expanded(
                        child: _iosDropdown<String>(
                          value: _selectedFoodId,
                          items: _foodCatalog.map((f) => f.id).toList(),
                          itemLabels: {
                            for (final f in _foodCatalog)
                              f.id: '${f.name} (${f.cal} kcal, ${f.prot.round()}g P/100g)',
                          },
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedFoodId = v);
                          },
                        ),
                      ),
                      if (_foodCatalog.length > 1) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () {
                            final removed = _foodCatalog.firstWhere((f) => f.id == _selectedFoodId);
                            setState(() {
                              _foodCatalog.removeWhere((f) => f.id == _selectedFoodId);
                              _selectedFoodId = _foodCatalog.first.id;
                            });
                            _saveState();
                            _showToast('Removed ${removed.name} from catalog');
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: PolarisColors.textSecondary),
                          tooltip: 'Remove from catalog',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PolarisColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _iosTextField(
                          controller: _customFoodNameCtrl,
                          hint: 'Custom food name (e.g. Protein Shake)',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _labeledNumberInput('Cal/100g', _customFoodCalCtrl, onChanged: (_) => setState(() {}))),
                            const SizedBox(width: 6),
                            Expanded(child: _labeledNumberInput('Carb/100g', _customFoodCarbCtrl, onChanged: (_) => setState(() {}))),
                            const SizedBox(width: 6),
                            Expanded(child: _labeledNumberInput('Prot/100g', _customFoodProtCtrl, onChanged: (_) => setState(() {}))),
                            const SizedBox(width: 6),
                            Expanded(child: _labeledNumberInput('Fib/100g', _customFoodFiberCtrl, onChanged: (_) => setState(() {}))),
                          ],
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeColor: PolarisColors.green,
                          title: const Text(
                            'Save to my Food Catalog for future days',
                            style: TextStyle(fontSize: 11, color: PolarisColors.textSecondary),
                          ),
                          value: _saveCustomFoodToCatalog,
                          onChanged: (v) => setState(() => _saveCustomFoodToCatalog = v ?? true),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _iosTextField(
                        controller: _mealQtyCtrl,
                        hint: 'Grams (e.g. 150)',
                        isNumber: true,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _iosDropdown<String>(
                        value: _selectedMealSlot,
                        items: const ['Breakfast', 'Lunch', 'Pre/Post Workout', 'Dinner', 'Snack'],
                        onChanged: (v) => setState(() => _selectedMealSlot = v ?? 'Breakfast'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: PolarisColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Auto-Calculated', style: TextStyle(fontSize: 11, color: PolarisColors.textSecondary)),
                      Text(
                        '${livePreview['cal']} kcal • ${livePreview['carb']}g C • ${livePreview['prot']}g P • ${livePreview['fiber']}g Fib',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PolarisColors.green),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _pillButton(
                    label: '+ Calculate & Log Food Item',
                    bg: PolarisColors.green,
                    fg: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    onTap: () {
                      final calc = _calculateActiveFoodMacros();
                      String foodName;
                      if (_isCustomFoodMode) {
                        foodName = _customFoodNameCtrl.text.trim().isEmpty
                            ? 'Custom Meal'
                            : _customFoodNameCtrl.text.trim();
                        if (_saveCustomFoodToCatalog) {
                          final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
                          final cal100 = (int.tryParse(_customFoodCalCtrl.text) ?? 200).clamp(0, 900);
                          final carb100 = (double.tryParse(_customFoodCarbCtrl.text) ?? 20).clamp(0.0, 100.0);
                          final prot100 = (double.tryParse(_customFoodProtCtrl.text) ?? 25).clamp(0.0, 100.0);
                          final fib100 = (double.tryParse(_customFoodFiberCtrl.text) ?? 4).clamp(0.0, 100.0);
                          final fat100 = math.max(0.0, (cal100 - (carb100 * 4 + prot100 * 4)) / 9.0);
                          _foodCatalog.insert(
                            0,
                            FoodItemRef(
                              id: newId,
                              name: foodName,
                              cal: cal100,
                              carb: carb100,
                              prot: prot100,
                              fiber: fib100,
                              fat: fat100,
                              isCustom: true,
                            ),
                          );
                          _selectedFoodId = newId;
                        }
                      } else {
                        foodName = _foodCatalog
                            .firstWhere((f) => f.id == _selectedFoodId, orElse: () => _foodCatalog.first)
                            .name;
                      }

                      final entry = MealEntry(
                        id: 'm_${DateTime.now().millisecondsSinceEpoch}',
                        name: foodName,
                        grams: calc['grams']!,
                        slot: _selectedMealSlot,
                        calories: calc['cal']!,
                        carbs: calc['carb']!,
                        protein: calc['prot']!,
                        fiber: calc['fiber']!,
                        fat: calc['fat']!,
                        time: _currentTimeString(),
                      );
                      setState(() => _meals.insert(0, entry));
                      _logTimeline(
                        'meal',
                        'Logged $_selectedMealSlot: ${entry.name} (${entry.grams}g)',
                        '+${entry.calories} kcal • ${entry.protein}g P',
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text('Logged Today', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
            child: _meals.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('No meals logged today.', style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary)),
                    ),
                  )
                : Column(
                    children: _meals.map((m) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: PolarisColors.divider, width: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${m.name} (${m.grams}g • ${m.slot})',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${m.calories} kcal • ${m.protein}g P • ${m.carbs}g C • ${m.fiber}g Fib',
                                    style: const TextStyle(fontSize: 11, color: PolarisColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() => _meals.removeWhere((item) => item.id == m.id));
                                _saveState();
                              },
                              child: const Icon(Icons.close_rounded, size: 16, color: PolarisColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ] else if (_fuelSubTab == 1) ...[
          // Biometric Diet Planner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Biometric Diet Planner', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const Text(
                  'Mifflin-St Jeor BMR & TDEE macro calculator',
                  style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _labeledNumberInput(
                        'Age',
                        _planAgeCtrl,
                        onChanged: (v) => setState(() => _age = (int.tryParse(v) ?? 25).clamp(14, 95)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _labeledNumberInput(
                        'Height (cm)',
                        _planHeightCtrl,
                        onChanged: (v) => setState(() => _heightCm = (int.tryParse(v) ?? 175).clamp(120, 230)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _labeledNumberInput(
                        'Weight (kg)',
                        _planWeightCtrl,
                        onChanged: (v) => setState(() => _weightKg = (int.tryParse(v) ?? 72).clamp(35, 220)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _iosDropdown<String>(
                        value: _gender,
                        items: const ['male', 'female'],
                        itemLabels: const {'male': 'Male', 'female': 'Female'},
                        onChanged: (v) => setState(() => _gender = v ?? 'male'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _iosDropdown<double>(
                        value: _activityFactor,
                        items: const [1.2, 1.375, 1.55, 1.725, 1.9],
                        itemLabels: {
                          1.2: 'Sedentary',
                          1.375: 'Lightly Active',
                          1.55: 'Moderately Active',
                          1.725: 'Very Active',
                          1.9: 'Athlete (2x/day)',
                        },
                        onChanged: (v) => setState(() => _activityFactor = v ?? 1.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _iosDropdown<String>(
                  value: _goal,
                  items: const ['loss', 'leancut', 'maintain', 'leangain', 'gain'],
                  itemLabels: const {
                    'loss': 'Weight Loss (-500 kcal)',
                    'leancut': 'Lean Cut (-250 kcal)',
                    'maintain': 'Maintenance (TDEE)',
                    'leangain': 'Lean Muscle Gain (+300 kcal)',
                    'gain': 'Mass Gain (+500 kcal)',
                  },
                  onChanged: (v) => setState(() => _goal = v ?? 'leangain'),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PolarisColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Recommended Target', style: TextStyle(fontSize: 11, color: PolarisColors.textSecondary)),
                              Text(
                                '${dietPlan['cal']} kcal',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: PolarisColors.green),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('BMR: ${dietPlan['bmr']} kcal', style: const TextStyle(fontSize: 11, color: PolarisColors.textSecondary)),
                              Text('TDEE: ${dietPlan['tdee']} kcal', style: const TextStyle(fontSize: 11, color: PolarisColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _planPill('Carbs', '${dietPlan['carb']}g')),
                          const SizedBox(width: 6),
                          Expanded(child: _planPill('Protein', '${dietPlan['prot']}g')),
                          const SizedBox(width: 6),
                          Expanded(child: _planPill('Fiber', '${dietPlan['fiber']}g')),
                          const SizedBox(width: 6),
                          Expanded(child: _planPill('Fats', '${dietPlan['fat']}g')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: _pillButton(
                          label: '⚡ Apply Targets to Meal & Water Tracker',
                          bg: Colors.white,
                          fg: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          onTap: () {
                            setState(() {
                              _targetCal = dietPlan['cal']!;
                              _targetCarb = dietPlan['carb']!;
                              _targetProt = dietPlan['prot']!;
                              _targetFiber = dietPlan['fiber']!;
                              _targetFat = dietPlan['fat']!;
                              _waterTarget = dietPlan['water']!;
                              _targetCalCtrl.text = '$_targetCal';
                              _targetCarbCtrl.text = '$_targetCarb';
                              _targetProtCtrl.text = '$_targetProt';
                              _targetFiberCtrl.text = '$_targetFiber';
                              _targetFatCtrl.text = '$_targetFat';
                              _waterTargetCtrl.text = '$_waterTarget';
                              _fuelSubTab = 0;
                            });
                            _logTimeline('meal', 'Applied Biometric Diet Targets', '$_targetCal kcal • ${_targetProt}g P');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Water Hydration Sub-Tab
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hydration Today', style: TextStyle(fontSize: 12, color: PolarisColors.blue, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('$_waterMl / $_waterTarget ml', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    Text(
                      '${((_waterMl / math.max(1, _waterTarget)) * 100).round()}%',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: PolarisColors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (_waterMl / math.max(1, _waterTarget)).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: PolarisColors.inputFill,
                    valueColor: const AlwaysStoppedAnimation(PolarisColors.blue),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _pillButton(label: '+100ml', bg: PolarisColors.inputFill, fg: Colors.white, onTap: () => _addWater(100, 'Hydration (+100ml)'))),
                    const SizedBox(width: 6),
                    Expanded(child: _pillButton(label: '+250ml', bg: PolarisColors.blue, fg: Colors.white, onTap: () => _addWater(250, 'Hydration (+250ml)'))),
                    const SizedBox(width: 6),
                    Expanded(child: _pillButton(label: '+500ml', bg: PolarisColors.blue, fg: Colors.white, onTap: () => _addWater(500, 'Hydration (+500ml)'))),
                    const SizedBox(width: 6),
                    Expanded(child: _pillButton(label: '-100ml', bg: PolarisColors.inputFill, fg: PolarisColors.textSecondary, onTap: () => _addWater(-100, 'Correction'))),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _iosTextField(controller: _waterCustomCtrl, hint: 'Custom ml', isNumber: true)),
                          const SizedBox(width: 6),
                          _pillButton(
                            label: 'Add',
                            bg: Colors.white,
                            fg: Colors.black,
                            onTap: () {
                              final ml = (int.tryParse(_waterCustomCtrl.text) ?? 0).clamp(10, 5000);
                              if (ml > 0) _addWater(ml, 'Custom Intake (+${ml}ml)');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _iosTextField(controller: _waterTargetCtrl, hint: 'Goal ml', isNumber: true)),
                          const SizedBox(width: 6),
                          _pillButton(
                            label: 'Goal',
                            bg: PolarisColors.inputFill,
                            fg: Colors.white,
                            onTap: () {
                              final tgt = (int.tryParse(_waterTargetCtrl.text) ?? 2500).clamp(500, 10000);
                              setState(() => _waterTarget = tgt);
                              _logTimeline('water', 'Set Water Goal: $tgt ml', 'Daily Target');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hydration History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _waterMl = 0;
                    _waterHistory.clear();
                  });
                  _saveState();
                  _showToast('Hydration reset');
                },
                child: const Text('Reset Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PolarisColors.crimson)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
            child: _waterHistory.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('No water logged today.', style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary)),
                    ),
                  )
                : Column(
                    children: _waterHistory.map((h) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: PolarisColors.divider, width: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(h.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                            Text('+${h.amount}ml • ${h.time}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PolarisColors.blue)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _waterMl = math.max(0, _waterMl - h.amount);
                                  _waterHistory.removeWhere((item) => item.id == h.id);
                                });
                                _saveState();
                              },
                              child: const Icon(Icons.close_rounded, size: 15, color: PolarisColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ],
    );
  }

  Widget _planPill(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: PolarisColors.textSecondary)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _macroBox(String label, String val, double pct, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: PolarisColors.surfaceElevated, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: PolarisColors.textSecondary)),
              Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: PolarisColors.surface,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  /// ==========================================================================
  /// TAB 5: EXPENSES (ADD/REMOVE CATEGORIES, CURRENCY SUPPORT, TRANSACTIONS)
  /// ==========================================================================
  Widget _buildExpensesTab() {
    if (!_expenseCategories.any((c) => c.name == _selectedExpenseCategory) &&
        _expenseCategories.isNotEmpty) {
      _selectedExpenseCategory = _expenseCategories.first.name;
    }

    final total = _expenses.fold<double>(0, (a, b) => a + b.amount);
    final Map<String, double> byCategory = {};
    for (final e in _expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }
    final sortedCatEntries = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final filteredExpenses = _expenseFilter == 'all'
        ? _expenses
        : _expenses.where((e) => e.category == _expenseFilter).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('Expenses', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            Text(
              '$_currencySymbol${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Category Breakdown Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Category Breakdown', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PolarisColors.textSecondary)),
                  Text('Distribution', style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),
              if (sortedCatEntries.isEmpty)
                const Text('No expenses recorded yet.', style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary))
              else
                ...sortedCatEntries.map((entry) {
                  final catObj = _expenseCategories.firstWhere(
                    (c) => c.name == entry.key,
                    orElse: () => const ExpenseCategoryItem(id: 'default', name: 'Other', icon: '💳', colorHex: 0xFF0A84FF),
                  );
                  final pct = total > 0 ? (entry.value / total).clamp(0.0, 1.0) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${catObj.icon} ${entry.key}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Text(
                              '$_currencySymbol${entry.value.toStringAsFixed(2)} (${(pct * 100).round()}%)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: PolarisColors.inputFill,
                            valueColor: AlwaysStoppedAnimation(Color(catObj.colorHex)),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // New Expense + Category Manager Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Expense', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  GestureDetector(
                    onTap: () => setState(() => _showCustomCategoryCreator = !_showCustomCategoryCreator),
                    child: Text(
                      _showCustomCategoryCreator ? 'Close Categories' : '+ / - Categories',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PolarisColors.blue),
                    ),
                  ),
                ],
              ),
              if (_showCustomCategoryCreator) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: PolarisColors.surfaceElevated, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _iosTextField(controller: _newCatNameCtrl, hint: 'Category name (e.g. Coffee)')),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 72,
                            child: _iosDropdown<String>(
                              value: _newCategoryIcon,
                              items: const ['☕', '📚', '🎒', '⚡', '🎯', '✈️'],
                              onChanged: (v) => setState(() => _newCategoryIcon = v ?? '☕'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _pillButton(
                            label: 'Add',
                            bg: Colors.white,
                            fg: Colors.black,
                            onTap: () {
                              final name = _newCatNameCtrl.text.trim();
                              if (name.isEmpty) return;
                              if (_expenseCategories.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
                                _showToast('Category already exists');
                                return;
                              }
                              const palette = [0xFF30D158, 0xFF0A84FF, 0xFFFF5500, 0xFFFF9F0A, 0xFFBF5AF2];
                              final colorHex = palette[_expenseCategories.length % palette.length];
                              setState(() {
                                _expenseCategories.add(
                                  ExpenseCategoryItem(
                                    id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                                    name: name,
                                    icon: _newCategoryIcon,
                                    colorHex: colorHex,
                                  ),
                                );
                                _selectedExpenseCategory = name;
                                _newCatNameCtrl.clear();
                              });
                              _logTimeline('expense', 'Added Category: $_newCategoryIcon $name', 'Finance');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _expenseCategories.map((c) {
                          return Chip(
                            backgroundColor: PolarisColors.surface,
                            label: Text('${c.icon} ${c.name}', style: const TextStyle(fontSize: 11)),
                            deleteIcon: const Icon(Icons.close_rounded, size: 14),
                            onDeleted: () {
                              if (_expenseCategories.length <= 1) {
                                _showToast('Keep at least 1 category');
                                return;
                              }
                              setState(() {
                                _expenseCategories.removeWhere((item) => item.id == c.id);
                                _selectedExpenseCategory = _expenseCategories.first.name;
                              });
                              _saveState();
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _iosTextField(controller: _expDescCtrl, hint: 'Merchant or item'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _iosTextField(controller: _expAmountCtrl, hint: '${_currencySymbol}0.00', isNumber: true),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _iosDropdown<String>(
                      value: _selectedExpenseCategory,
                      items: _expenseCategories.map((c) => c.name).toList(),
                      itemLabels: {for (final c in _expenseCategories) c.name: '${c.icon} ${c.name}'},
                      onChanged: (v) => setState(() => _selectedExpenseCategory = v ?? _expenseCategories.first.name),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _iosDropdown<String>(
                      value: _selectedExpenseMethod,
                      items: const ['Card', 'UPI / Instant', 'Cash'],
                      onChanged: (v) => setState(() => _selectedExpenseMethod = v ?? 'Card'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _pillButton(
                  label: '+ Record Expense',
                  bg: Colors.white,
                  fg: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  onTap: () {
                    final title = _expDescCtrl.text.trim();
                    final amt = double.tryParse(_expAmountCtrl.text) ?? 0;
                    if (title.isEmpty || amt <= 0) {
                      _showToast('Enter a valid merchant and amount');
                      return;
                    }
                    final ex = ExpenseItem(
                      id: 'ex_${DateTime.now().millisecondsSinceEpoch}',
                      title: title,
                      amount: amt,
                      category: _selectedExpenseCategory,
                      method: _selectedExpenseMethod,
                      time: _currentTimeString(),
                      date: _todayIsoDate(),
                    );
                    setState(() {
                      _expenses.insert(0, ex);
                      _expDescCtrl.clear();
                      _expAmountCtrl.clear();
                    });
                    _logTimeline('expense', 'Expense: ${ex.title}', '$_currencySymbol${ex.amount.toStringAsFixed(2)} • ${ex.category}');
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('All', _expenseFilter == 'all', () => setState(() => _expenseFilter = 'all')),
              ..._expenseCategories.map(
                (c) => _filterChip('${c.icon} ${c.name}', _expenseFilter == c.name, () => setState(() => _expenseFilter = c.name)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
          child: filteredExpenses.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text('No transactions in this category.', style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary)),
                  ),
                )
              : Column(
                  children: filteredExpenses.map((e) {
                    final catObj = _expenseCategories.firstWhere(
                      (c) => c.name == e.category,
                      orElse: () => const ExpenseCategoryItem(id: 'def', name: 'General', icon: '💳', colorHex: 0xFF0A84FF),
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: PolarisColors.divider, width: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(color: PolarisColors.inputFill, shape: BoxShape.circle),
                                  child: Text(catObj.icon, style: const TextStyle(fontSize: 15)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text('${e.category} • ${e.method} • ${e.time}', style: const TextStyle(fontSize: 11, color: PolarisColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text('-$_currencySymbol${e.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() => _expenses.removeWhere((item) => item.id == e.id));
                                  _saveState();
                                },
                                child: const Icon(Icons.close_rounded, size: 16, color: PolarisColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  /// ==========================================================================
  /// TAB 6: VOICE & TEXT JOURNAL + ACTIVITY TIMELINE
  /// ==========================================================================
  Widget _buildJournalAndTimelineTab() {
    final filteredJournals = _journalFilter == 'all'
        ? _journals
        : _journals.where((j) => j.type == _journalFilter).toList();

    final filteredTimeline = _timelineFilter == 'all'
        ? _timeline
        : _timeline.where((ev) => ev.category == _timelineFilter).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _journalSubTab == 0 ? 'Journal' : 'Timeline',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  _segTabButton('Journal', _journalSubTab == 0, () => setState(() => _journalSubTab = 0)),
                  _segTabButton('Timeline', _journalSubTab == 1, () => setState(() => _journalSubTab = 1)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_journalSubTab == 0) ...[
          // Real Voice Memo Recorder Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _isRecordingVoice ? PolarisColors.crimson : PolarisColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isRecordingVoice ? 'Recording Microphone...' : 'Voice Note Recorder',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Text(_formatStopwatch(_voiceSeconds), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 12),
                // Animated Waveform Visualizer
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: PolarisColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(26, (i) {
                      final h = _isRecordingVoice
                          ? 10.0 + ((i * 13 + _voiceSeconds * 19) % 26)
                          : 8.0 + ((i * 11) % 18);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 3,
                        height: h,
                        decoration: BoxDecoration(
                          color: _isRecordingVoice
                              ? PolarisColors.crimson
                              : PolarisColors.textSecondary.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _iosTextField(controller: _voiceTitleCtrl, hint: 'Voice memo title...'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _iosDropdown<String>(
                        value: _selectedVoiceMood,
                        items: const ['🔥 Focused', '⚡ Energized', '🧭 Reflective', '🏔️ Grateful'],
                        onChanged: (v) => setState(() => _selectedVoiceMood = v ?? '🔥 Focused'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _pillButton(
                        label: _isRecordingVoice ? 'Stop Recording' : '🎙️ Record Voice',
                        bg: _isRecordingVoice ? PolarisColors.crimson : PolarisColors.inputFill,
                        fg: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        onTap: _toggleVoiceRecording,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _pillButton(
                      label: 'Save Voice Note',
                      bg: Colors.white,
                      fg: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      onTap: () async {
                        if (_isRecordingVoice) {
                          await _toggleVoiceRecording();
                        }
                        final dur = _formatStopwatch(math.max(3, _voiceSeconds));
                        final customTitle = _voiceTitleCtrl.text.trim();
                        final entryTitle = customTitle.isNotEmpty
                            ? customTitle
                            : 'Voice Memo (${_currentTimeString()})';
                        final j = JournalEntry(
                          id: 'j_${DateTime.now().millisecondsSinceEpoch}',
                          type: 'voice',
                          title: entryTitle,
                          mood: _selectedVoiceMood,
                          duration: dur,
                          body: _currentRecordingPath != null
                              ? 'Recorded audio file ($dur) — tap Play below to listen.'
                              : 'Voice memo ($dur) — "$entryTitle"',
                          time: _currentTimeString(),
                          date: _formatShortDateLabel(DateTime.now()),
                          audioFilePath: _currentRecordingPath,
                        );
                        setState(() {
                          _journals.insert(0, j);
                          _voiceSeconds = 0;
                          _currentRecordingPath = null;
                          _voiceTitleCtrl.clear();
                        });
                        _logTimeline('journal', 'Saved Voice Note: ${j.title}', '🎙️ $dur');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Written Entry Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Written Entry', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _iosTextField(controller: _journalTitleCtrl, hint: 'Entry title'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _iosDropdown<String>(
                        value: _selectedTextMood,
                        items: const ['🔥 Focused', '⚡ Energized', '🧭 Reflective', '🏔️ Grateful'],
                        onChanged: (v) => setState(() => _selectedTextMood = v ?? '🧭 Reflective'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _iosTextField(controller: _journalBodyCtrl, hint: 'Write your thoughts...', maxLines: 3),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: _pillButton(
                    label: '+ Save Written Entry',
                    bg: Colors.white,
                    fg: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    onTap: () {
                      final title = _journalTitleCtrl.text.trim();
                      final body = _journalBodyCtrl.text.trim();
                      if (title.isEmpty && body.isEmpty) {
                        _showToast('Enter a title or note first');
                        return;
                      }
                      final j = JournalEntry(
                        id: 'j_${DateTime.now().millisecondsSinceEpoch}',
                        type: 'text',
                        title: title.isEmpty ? 'Daily Reflection' : title,
                        mood: _selectedTextMood,
                        body: body.isEmpty ? title : body,
                        time: _currentTimeString(),
                        date: _formatShortDateLabel(DateTime.now()),
                      );
                      setState(() {
                        _journals.insert(0, j);
                        _journalTitleCtrl.clear();
                        _journalBodyCtrl.clear();
                      });
                      _logTimeline('journal', 'Saved Journal: ${j.title}', j.mood);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              _filterChip('All Records', _journalFilter == 'all', () => setState(() => _journalFilter = 'all')),
              _filterChip('🎙️ Voice Notes', _journalFilter == 'voice', () => setState(() => _journalFilter = 'voice')),
              _filterChip('📝 Text Logs', _journalFilter == 'text', () => setState(() => _journalFilter = 'text')),
            ],
          ),
          const SizedBox(height: 12),

          if (filteredJournals.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
              child: const Center(
                child: Text('No journal entries yet.', style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary)),
              ),
            )
          else
            ...filteredJournals.map(
              (j) {
                final isPlaying = _activePlayingVoiceId == j.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                j.type == 'voice' ? '🎙️ Voice' : '📝 Written',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: j.type == 'voice' ? PolarisColors.crimson : PolarisColors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(j.mood, style: const TextStyle(fontSize: 11, color: PolarisColors.textSecondary)),
                            ],
                          ),
                          Row(
                            children: [
                              Text('${j.date} • ${j.time}', style: const TextStyle(fontSize: 11, color: PolarisColors.textSecondary)),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  if (_activePlayingVoiceId == j.id) {
                                    _audioPlayer.stop();
                                    _activePlayingVoiceId = null;
                                  }
                                  setState(() => _journals.removeWhere((item) => item.id == j.id));
                                  _saveState();
                                },
                                child: const Icon(Icons.close_rounded, size: 16, color: PolarisColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(j.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(j.body, style: const TextStyle(fontSize: 12, color: PolarisColors.textSecondary, height: 1.4)),
                      if (j.type == 'voice') ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _pillButton(
                              label: isPlaying ? '⏹ Stop Playback' : '▶ Play Voice Note',
                              bg: isPlaying ? Colors.white : PolarisColors.inputFill,
                              fg: isPlaying ? Colors.black : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              onTap: () => _togglePlayVoiceEntry(j),
                            ),
                            Text(
                              isPlaying && _audioDuration.inSeconds > 0
                                  ? '${_formatStopwatch(_audioPosition.inSeconds)} / ${_formatStopwatch(_audioDuration.inSeconds)}'
                                  : j.duration,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PolarisColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ] else ...[
          // ACTIVITY TIMELINE SUB-TAB
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Expanded(
                  child: _iosTextField(controller: _milestoneNoteCtrl, hint: 'Log a custom milestone...'),
                ),
                const SizedBox(width: 8),
                _pillButton(
                  label: '+ Log',
                  bg: Colors.white,
                  fg: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  onTap: () {
                    final note = _milestoneNoteCtrl.text.trim();
                    if (note.isEmpty) return;
                    _milestoneNoteCtrl.clear();
                    _logTimeline('journal', note, '🏔️ Milestone');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', _timelineFilter == 'all', () => setState(() => _timelineFilter = 'all')),
                _filterChip('🔥 Streak', _timelineFilter == 'streak', () => setState(() => _timelineFilter = 'streak')),
                _filterChip('⚡ Workout', _timelineFilter == 'workout', () => setState(() => _timelineFilter = 'workout')),
                _filterChip('☑️ Todo', _timelineFilter == 'todo', () => setState(() => _timelineFilter = 'todo')),
                _filterChip('💧 Water', _timelineFilter == 'water', () => setState(() => _timelineFilter = 'water')),
                _filterChip('🥗 Meal', _timelineFilter == 'meal', () => setState(() => _timelineFilter = 'meal')),
                _filterChip('💳 Expense', _timelineFilter == 'expense', () => setState(() => _timelineFilter = 'expense')),
                _filterChip('🎙️ Journal', _timelineFilter == 'journal', () => setState(() => _timelineFilter = 'journal')),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(color: PolarisColors.surface, borderRadius: BorderRadius.circular(20)),
            child: filteredTimeline.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('No activity in this category yet.', style: TextStyle(fontSize: 12, color: PolarisColors.textSecondary)),
                    ),
                  )
                : Column(
                    children: filteredTimeline.map((ev) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: PolarisColors.divider, width: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ev.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text('${ev.badge} • ${ev.date}', style: const TextStyle(fontSize: 11, color: PolarisColors.textSecondary)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Text(ev.time, style: const TextStyle(fontSize: 11, color: PolarisColors.textSecondary, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _timeline.removeWhere((item) => item.id == ev.id));
                                    _saveState();
                                  },
                                  child: const Icon(Icons.close_rounded, size: 14, color: PolarisColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ],
    );
  }

  /// ==========================================================================
  /// SHARED REUSABLE UI WIDGETS
  /// ==========================================================================
  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: active ? Colors.white : PolarisColors.surface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? Colors.black : PolarisColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _labeledNumberInput(String label, TextEditingController ctrl, {ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: PolarisColors.textSecondary)),
        const SizedBox(height: 4),
        _iosTextField(controller: ctrl, hint: label, isNumber: true, onChanged: onChanged),
      ],
    );
  }

  Widget _iosTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(fontSize: 13, color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: PolarisColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: PolarisColors.inputFill,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _iosDropdown<T>({
    required T value,
    required List<T> items,
    Map<T, String>? itemLabels,
    required ValueChanged<T?> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: PolarisColors.inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: safeValue,
          isExpanded: true,
          dropdownColor: PolarisColors.surfaceElevated,
          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabels?[item] ?? item.toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _pillButton({
    required String label,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
        ),
      ),
    );
  }

  Widget _segTabButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? PolarisColors.inputFill : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            color: active ? Colors.white : PolarisColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ActivityRingPainter extends CustomPainter {
  final double progress;
  _ActivityRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;

    final trackPaint = Paint()
      ..color = PolarisColors.inputFill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11;
    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..shader = const LinearGradient(
        colors: [PolarisColors.crimson, PolarisColors.coral],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 11;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ActivityRingPainter oldDelegate) => oldDelegate.progress != progress;
}
