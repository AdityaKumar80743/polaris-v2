# POLARIS — Path to Reach the Top (Flutter Mobile App v3.0)

A production-ready, cross-platform Flutter mobile application (`iOS` & `Android`) designed with a native OLED dark interface (`#000000` canvas, `#1C1C1E` grouped surfaces, `#2C2C2E` inset controls).

## What's New in v3.0
1. **Automatic Daily Midnight Reset Engine**:
   - Tracks `lastActiveDate` (`YYYY-MM-DD`) in `SharedPreferences`.
   - Automatically resets daily workout sets (`completedToday = 0`), water intake (`0 ml`), daily meal logs, and active stopwatch timer at midnight (on app launch, resume, or live rollover), while preserving macro targets, custom food catalog, expense history, journal entries, and timeline history.
   - Automatically unchecks completed **repeating tasks** (`Daily`, `Weekly`, `Custom N-days`) and advances their due date to the new day.
2. **Fresh User State (Zero Hardcoded Demo Data)**:
   - Every new user starts with a clean slate (`0` workouts, `0` tasks, `0 ml` water, `0` meals, `0` expenses, `0` journals) anchored to the device's real `DateTime.now()` clock and calendar.
   - Optional **"Load Demo Data"** and **"Factory Reset"** buttons are available inside the Settings & Modules sheet.
3. **Daily Streak Counter (`🔥 Day Streak`)**:
   - Automatically increments your daily streak when your daily goal completion reaches `>= 80%` (or when you tap **Claim Daily Streak**), tracks your all-time **Best Streak**, and displays a **7-Day Consistency Strip** on the Summary Dashboard.
4. **Add & Remove Modules + Full CRUD**:
   - Toggle individual modules (**Workouts**, **Tasks & Schedule**, **Nutrition & Water**, **Expenses**, **Journal**) on or off to customize both the bottom navigation bar and Summary dashboard tiles.
   - Full **Add, Edit, Decrement (`-1 Set`), and Remove** controls for workouts, tasks, custom foods, expense categories, water logs, and timeline events.
5. **Real Voice Recording & Audio Playback**:
   - Uses `record`, `audioplayers`, and `path_provider` to record real `.m4a` voice notes to local device storage (`getApplicationDocumentsDirectory()`) and play them back with real audio streaming.

## Platform Permissions for Voice Recording

### iOS (`ios/Runner/Info.plist`)
Add the microphone usage description key inside `<dict>`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Polaris needs microphone access to record voice journal notes.</string>
```

### Android (`android/app/src/main/AndroidManifest.xml`)
Add the permission above `<application>`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

## Running the App
```bash
flutter pub get
flutter run
```
