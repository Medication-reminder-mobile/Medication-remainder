# MedRemind 💊

A cross-platform medication reminder and health tracking app built with Flutter. MedRemind helps patients stay on top of their medication schedules, enables caregivers to monitor adherence, and provides clinical-grade tools for healthcare professionals.

---

## Features

### Foundation & Backend Core (Member 1)
- **SQLite Database** — full local persistence via `sqflite` with 6 tables: users, medications, intake_logs, caregiver_patients, caregiver_tasks, doctor_notes
- **Authentication** — register, login, logout with SHA-256 password hashing and remember-me session persistence
- **Role System** — three roles: `individual_user`, `individual_caregiver`, `professional_caregiver` with role-based routing guards
- **Session Service** — user + role stored in SharedPreferences, auto-restored on app launch
- **Notifications** — `flutter_local_notifications` scheduled per medication time, cancel on delete/pause
- **Background Tasks** — `WorkManager` periodic task fires notifications even when app is closed
- **Voice Reminders** — TTS via `flutter_tts` speaks medication name at scheduled time
- **Models** — `UserModel`, `MedicationModel`, `IntakeLogModel`, `CaregiverLinkModel`, `CaregiverTaskModel`, `DoctorNoteModel`, `RbcEntryModel`

### Onboarding, Auth Screens & Patient Home (Member 2)
- **SplashScreen** — teal background, MedRemind logo, "Clinical Grade Security" badge, auto-navigates after session check
- **OnboardingScreen** — 3-page swiper ("Never miss a dose", "Stay on schedule", "Care for your loved ones"), Skip + arrow navigation, dot indicators
- **Auth Screen** — tab switcher (Login / Register), Google + Facebook buttons (UI), email + password fields, password strength bar, show/hide toggle, Remember me checkbox, Forgot password link
- **Role Selection** — 3 role cards with icons and descriptions, "Continue to Setup" button, "Already have an account? Log In" link, security banner
- **Patient Dashboard** — greeting with name, circular adherence progress, quick action buttons (Add Med / Log Intake), Today's Schedule horizontal cards, Weekly Health Report banner, Doctor's Note card, Refill Alert banner, Today's Timeline with "IN 15 MINS" highlight, Log button per item, FAB for quick add

### Additional Screens
- **Caregiver Dashboard** — patient roster, adherence overview, urgent missed doses alert, caregiver tasks
- **Medications Screen** — search, filter chips (All / Daily / Weekly / As Needed), medication cards with pill icon + status badge
- **Daily Intake Log** — timeline view, mark taken/missed, log all at once
- **Reports Screen** — weekly trend chart, monthly consistency, adherence stats, voice summary, export PDF
- **RBC Dashboard** — red blood cell health tracking with trend chart, metric cards (RBC count, Hemoglobin, Hematocrit, MCV), history log
- **Profile Screen** — user info, dark mode toggle, notification preferences, logout

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart) |
| State Management | Provider |
| Navigation | GoRouter |
| Local Database | sqflite + sqflite_common_ffi_web |
| Session | SharedPreferences |
| Notifications | flutter_local_notifications |
| Background Tasks | WorkManager |
| Voice / TTS | flutter_tts |
| Charts | fl_chart |
| Fonts | Google Fonts (Inter) |
| UI Extras | shimmer, percent_indicator, smooth_page_indicator |

---

## Project Structure

```
lib/
├── core/
│   ├── constants/       # AppColors, AppRoutes, AppTextStyles
│   ├── theme/           # AppTheme (light + dark)
│   └── utils/           # DateHelpers, Validators
├── models/              # Data models (User, Medication, IntakeLog, etc.)
├── providers/           # ChangeNotifier state (Auth, Medication, IntakeLog, Caregiver, RBC, Theme)
├── services/            # DB, Auth, Session, Notification, WorkManager, Voice
├── screens/
│   ├── auth_screen.dart
│   ├── onboarding_screen.dart
│   ├── role_selection_screen.dart
│   ├── splash_screen.dart
│   ├── caregiver/       # Caregiver dashboard + patient management
│   ├── meds/            # Add, Edit, Detail screens
│   ├── patient/         # Patient dashboard
│   ├── rbc/             # RBC health dashboard
│   ├── shell/           # AppShell with bottom navigation
│   ├── tabs/            # Meds, Log, Reports, Profile tabs
│   └── voice/           # Voice reminder screen
├── widgets/             # AppButton, AppTextField, PillIcon, MedIllustration
├── main.dart
└── router.dart
```

---

## Getting Started

### Prerequisites
- Flutter SDK `^3.11.5`
- Dart SDK `^3.x`
- Chrome (for web), Android emulator, or iOS simulator

### Install dependencies
```bash
flutter pub get
```

### Run on Chrome (web)
```bash
flutter run -d chrome --web-port 8080
```

### Run on Android / iOS
```bash
flutter run
```

### Run on Windows desktop
```bash
flutter run -d windows
```

---

## User Roles & Flow

```
Splash
  └── New user  → Onboarding → Role Selection → Register → Home
  └── Returning → Auto-login → Home (role-based)

Home (role-based)
  ├── individual_user        → Patient Dashboard
  ├── individual_caregiver   → Caregiver Dashboard
  └── professional_caregiver → Caregiver Dashboard
```

---

## Branches

| Branch | Description |
|--------|-------------|
| `main` | Stable, fully integrated code |
| `feature/foundation-backend-core` | Member 1 — DB, Auth, Services, Models |
| `feature/onboarding-auth-patient-home` | Member 2 — Onboarding, Auth UI, Patient Dashboard |

---

## Team

| Member | Task |
|--------|------|
| Member 1 | Foundation & Backend Core — database, auth, notifications, background tasks |
| Member 2 | Onboarding, Auth Screens & Patient Home — splash, onboarding, login/register, role selection, patient dashboard |

## 📋 System Design (Member 3)

- [System Design Overview](./docs/system-design/SYSTEM_DESIGN.md)
- [Architecture Diagram](./docs/system-design/ARCHITECTURE.md)
- [Database Design (ERD)](./docs/system-design/DATABASE_DESIGN.md)
- [Data Flow](./docs/system-design/DATA_FLOW.md)