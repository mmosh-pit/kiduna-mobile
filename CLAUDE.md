# RULES — MANDATORY — NO EXCEPTIONS

You MUST follow every rule in this document.
Before writing ANY code, re-read the relevant section.
NEVER run git commit. Output the commit message as text — the user commits.
Before EVERY push, run the verification checklist in Section 10.
If unsure, ask — do not guess.
Violation of these rules is considered a bug.

## APPROVAL RULE

```
NEVER auto-execute repository-changing actions. WAIT for user approval.

NEVER — not even with approval:
  - git add
  - git commit
  - git commit --amend
  - git rebase / git reset / git revert
  - git push --force
  The user does all of these. Claude only WRITES the commit message as text.

AUTO-RUN OK (no approval needed):
  - dart format .
  - flutter analyze
  - flutter test
  - dart run build_runner build
  - flutter pub get

APPROVAL REQUIRED (user must explicitly say):
  - git push (and only after the verification checklist passes — see Section 10)
  - git pull
  - Create / merge / delete branch
  - Create pull request
  - Install/remove packages (flutter pub add/remove)
  - Delete files (exception: build_runner regenerating .g.dart / .freezed.dart is fine)
  - Deploy anything
  - Any CI/CD trigger

EXACT APPROVAL WORDS:
  "commit message" / "commit" → output the message text ONLY. Do NOT run git.
  "push" → run verification checklist → if clean, pull then push
           → if NOT clean, fix issues, STOP, and ask the user to commit the fixes
  "deploy" → then deploy
  "add package X" → then add
  "delete file X" → then delete that file  (vague "delete" is NOT approval)

  "looks good", "ok", "nice", "sure" = NOT approval to push/deploy.
  If unsure → ASK: "Should I push this?"

WORKFLOW:
  1. User asks to write code → you WRITE code → STOP
  2. Show what you wrote and explain → STOP
  3. User reviews → gives next instruction
  4. User says "commit" → output the commit message text → STOP. User commits.
  5. User says "push" → run verification checklist:
       all clean  → git pull → git push
       any failure → fix it → STOP → new commit message → user commits → then push
  6. No approval word = no action
```

---

# CLAUDE.md — Flutter Development Guide

This document is the single source of truth for Flutter development in this project. Follow these rules strictly. Do not deviate unless explicitly asked.

---

## Platform Targets — Web, Mobile, and Desktop

This app ships on **web, mobile, AND desktop** — that is the reason it is built in Flutter.
Not a mobile-only app. Write every feature ONCE, in a generic, reusable way, so it behaves
and looks consistent on all three.

```
- Build for the available SPACE, not a device class. Use ResponsiveLayout and the
  breakpoints in core/utils/responsive.dart (see Section 22). Never hardcode a phone-only
  or desktop-only layout — a screen must reflow from narrow to wide.
- No platform forks unless a capability genuinely differs. When a Platform.isX / kIsWeb
  check is truly unavoidable, isolate it behind one small helper — never scatter platform
  checks through widgets.
- Design inputs for touch, mouse, trackpad, AND keyboard at once: pointer events, hover
  (MouseRegion), focus traversal, and keyboard shortcuts should all work.
- Reusable-first: shared widgets in shared/, styling in theme tokens (Section 22), logic in
  controllers/repositories — one implementation serves every platform.
- Sizes are relative, not fixed to one screen. Avoid absolute pixel layouts that only look
  right on a phone; prefer flexible constraints, Expanded/Flexible, and token spacing.
- Verify on more than one target before a change is "done": at minimum a wide (web/desktop)
  and a narrow (mobile) layout. `flutter build web` must stay green (see Section 24).
```

---

## 1. Project Structure

```
lib/
├── main.dart                          # Entry point — ONLY runApp() and MaterialApp setup
│
├── app/
│   ├── app.dart                       # Root widget — theme, router, global providers
│   ├── routes.dart                    # All route definitions in one file
│   └── injection.dart                 # Dependency injection — register all services/repos here
│
├── config/
│   ├── env.dart                       # Environment variables (API URLs, keys)
│   ├── theme.dart                     # App theme — colors, typography, spacing
│   ├── theme_extensions.dart          # Custom ThemeExtension classes for app-specific tokens
│   └── constants.dart                 # App-wide constants (durations, sizes, limits)
│
├── l10n/                              # ALL user-facing text lives here — see Section 21
│   └── app_en.arb                     # English strings — single language, one file
│
├── core/
│   ├── enums/                         # App-wide enums
│   │   ├── user_role.dart
│   │   └── order_status.dart
│   ├── errors/
│   │   └── exceptions.dart            # Custom exception classes — ONE error style, see Section 7
│   ├── interfaces/                    # Abstract classes / contracts
│   │   ├── base_repository.dart       # Repository interface
│   │   └── base_service.dart          # Service interface
│   ├── mixins/                        # Shared mixins
│   │   ├── form_validation_mixin.dart
│   │   └── pagination_mixin.dart
│   ├── network/
│   │   ├── api_client.dart            # HTTP client setup (Dio) with interceptors
│   │   ├── api_endpoints.dart         # All API endpoint paths as constants
│   │   ├── api_response.dart          # Generic API response wrapper
│   │   └── api_interceptors.dart      # Auth, logging, error interceptors
│   ├── utils/
│   │   ├── logger.dart                # App logger — ONLY way to log, never print()
│   │   ├── validators.dart            # Input validation functions
│   │   ├── formatters.dart            # Date, currency, text formatters
│   │   └── responsive.dart            # Screen size helpers, breakpoints
│   └── extensions/
│       ├── string_extensions.dart     # String helper methods
│       ├── context_extensions.dart    # BuildContext helpers (theme, mediaquery, navigator)
│       └── datetime_extensions.dart   # DateTime helpers
│
├── data/
│   ├── models/                        # Data classes — JSON ↔ Dart objects
│   │   ├── user_model.dart
│   │   └── user_model.g.dart          # Generated — DO NOT edit, gitignored (CI regenerates)
│   ├── repositories/                  # Data source decision layer
│   │   └── user_repository.dart       # Implements interface. Decides: API or cache? Returns model.
│   ├── services/                      # Remote API calls — no business logic
│   │   └── user_service.dart          # Makes HTTP calls, returns raw response
│   └── local/                         # Local data sources — cache, secure storage, DB
│       ├── local_storage.dart         # SharedPreferences wrapper
│       ├── secure_storage.dart        # flutter_secure_storage wrapper (tokens, keys)
│       └── cache_manager.dart         # Cache with expiry logic
│
├── features/                          # Feature-based modules — each feature is self-contained
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── widgets/
│   │   │   ├── login_form.dart
│   │   │   └── social_login_button.dart
│   │   ├── controllers/
│   │   │   └── auth_controller.dart   # Business logic + state for auth
│   │   └── enums/                     # Feature-specific enums (if only used here)
│   │       └── auth_status.dart
│   ├── home/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── controllers/
│   └── settings/
│       ├── screens/
│       ├── widgets/
│       └── controllers/
│
└── shared/                            # Reusable across features
    ├── widgets/
    │   ├── app_button.dart            # Custom button used everywhere
    │   ├── app_text_field.dart        # Custom text field
    │   ├── loading_indicator.dart     # Consistent loading spinner
    │   ├── error_display.dart         # Consistent error display
    │   └── empty_state.dart           # Consistent empty state
    └── layouts/
        ├── responsive_layout.dart     # Handles mobile/tablet/desktop
        └── scaffold_with_nav.dart     # Common scaffold with navigation

assets/
├── images/                            # PNG, JPG, WebP — naming: snake_case (login_bg.png)
├── icons/                             # SVG icons — naming: ic_snake_case.svg (ic_arrow_back.svg)
├── fonts/                             # Custom font files (.ttf, .otf)
└── animations/                        # Lottie JSON files — naming: anim_snake_case.json

test/
├── unit/                              # Model, service, repository tests
├── widget/                            # Individual widget tests
├── integration/                       # Full flow tests
└── mocks/                             # Shared mock classes

# Project root files
analysis_options.yaml                  # Lint rules — MANDATORY, see Section 20
l10n.yaml                              # Localization config — see Section 21
.env                                   # Env values — gitignored, loaded by flutter_dotenv, see Section 23
.env.example                           # Committed template with empty values
```

### Rules

- Every feature folder is self-contained — screens, widgets, controllers inside it
- Shared widgets used by 2+ features go in `shared/widgets/`
- If a widget is used by only ONE feature, keep it inside that feature's `widgets/` folder
- Models live in `data/models/` — never inside features
- Services live in `data/services/` — never inside features
- Enums used app-wide → `core/enums/`. Enums used by one feature → inside that feature's `enums/`
- Abstract classes/interfaces → `core/interfaces/`
- Mixins used across features → `core/mixins/`. Mixins used by one feature → inside that feature
- One file = one public class. File name matches class name in snake_case

---

## 2. Naming Conventions

### Files

```
All files:              snake_case.dart
Screens:                login_screen.dart              (always _screen suffix, NEVER _page)
Widgets:                social_login_button.dart
Controllers:            auth_controller.dart            (if using Bloc: auth_bloc.dart or auth_cubit.dart)
Models:                 user_model.dart
Services:               user_service.dart
Repositories:           user_repository.dart
Interfaces:             base_repository.dart
Mixins:                 form_validation_mixin.dart      (_mixin suffix)
Enums:                  user_role.dart
Extensions:             string_extensions.dart
Constants:              app_constants.dart
Tests:                  login_screen_test.dart           (original_name + _test)
```

### Classes

```
Widgets/Screens:        LoginScreen, SocialLoginButton          (PascalCase)
Controllers:            AuthController                          (PascalCase)
Blocs:                  AuthBloc, AuthCubit                     (if using Bloc pattern)
Models:                 UserModel, ProductModel                 (PascalCase)
Services:               UserService, AuthService                (PascalCase)
Repositories:           UserRepository                          (PascalCase)
Interfaces:             BaseRepository, BaseService             (PascalCase, Base prefix for abstract)
Mixins:                 FormValidationMixin                     (PascalCase, Mixin suffix)
Enums:                  UserRole, OrderStatus                   (PascalCase)
Enum values:            UserRole.admin, OrderStatus.pending     (camelCase)
```

### Variables & Functions

```
Variables:              userName, isLoading, itemCount           (camelCase)
Functions:              getUserName(), fetchOrders()             (camelCase)
Private:                _internalState, _calculateTotal()       (_prefixed camelCase)
Boolean:                isActive, hasPermission, canEdit        (is/has/can prefix)
Lists:                  users, orderItems, selectedIds          (plural noun)
Callbacks:              onPressed, onChanged, onSubmitted        (on prefix)
```

### Constants

```
File-level:             const kMaxRetries = 3;                  (k prefix + camelCase)
                        const kAnimationDuration = Duration(milliseconds: 300);
Class-level:            static const maxItems = 50;             (camelCase)
```

### Assets

```
Images:                 login_bg.png, user_avatar.png           (snake_case)
Icons:                  ic_arrow_back.svg, ic_close.svg         (ic_ prefix + snake_case)
Animations:             anim_loading.json, anim_success.json    (anim_ prefix + snake_case)
Fonts:                  Roboto-Regular.ttf                      (original font name)

NEVER:
  - loginBg.png (camelCase)
  - login-bg.png (kebab-case)
  - LoginBG.PNG (uppercase extension)
```

### Screen vs Page

```
ALWAYS use "Screen": LoginScreen, HomeScreen, SettingsScreen
NEVER use "Page":    LoginPage, HomePage, SettingsPage

File: login_screen.dart   ✅
File: login_page.dart     ❌
```

---

## 3. Code Organization Rules

### Code Formatting — Write Clean From The Start

```
Write clean, formatted Dart code from the start.
Do not rely on dart format to fix your formatting — write it correct the first time.

- 2-space indentation (Dart standard)
- Single quotes for strings ('hello' not "hello")
- Trailing comma after last parameter in multi-line function calls and widget trees
- One blank line between methods — never two or more
- No trailing whitespace on any line
- Consistent spacing around operators (a + b, not a+b)
- Opening brace on same line: if (condition) {
- Always use curly braces: if (x) { return; } — never: if (x) return;
```

### Widget Rules

```
- One public widget per file
- Max 300 lines per file — if exceeds, extract sub-widgets into separate files
- Keep build() method under 50 lines — extract into separate widget classes with const
  constructors (preferred). Private _buildX() methods only for tiny non-const chunks —
  they do NOT help rebuild performance, a const widget class does
- Use const constructors wherever possible — improves rebuild performance
- Avoid widget nesting deeper than 3 levels — extract into named widget
```

### Ordering Inside a File

```dart
// 1. Imports (grouped: dart → package → relative, alphabetical within group)
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../core/utils/logger.dart';
import '../models/user_model.dart';

// 2. Class declaration with const constructor
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key, required this.userId});

  // 3. Final fields (public)
  final String userId;

  // 4. Build method
  @override
  Widget build(BuildContext context) { ... }

  // 5. Private helper methods (below build)
  Widget _buildHeader() { ... }
  Widget _buildBody() { ... }
}
```

### Separation Rules

```
Widget:         ONLY UI rendering + user interaction handling
Controller:     ONLY business logic + state management
Repository:     ONLY data source selection (API vs cache)
Service:        ONLY raw API/DB calls
Model:          ONLY data structure + serialization

NEVER:
- API call from widget
- UI code in service
- Business logic in model
- Navigation logic in service
- State management in widget (except local setState for simple toggles)
```

### Import Rules

```
- Use relative imports within the same package
- Use package imports for external packages
- Never use dynamic imports
- Never leave unused imports — remove immediately
- Group imports with blank line between groups:
    1. dart: libraries
    2. package: libraries
    3. relative imports
```

### Where Things Go

```
Enums used app-wide           → core/enums/
Enums used by one feature     → features/feature_name/enums/
Mixins used app-wide          → core/mixins/
Mixins used by one feature    → inside that feature folder
Abstract classes / interfaces → core/interfaces/
```

---

## 4. State Management

### Approach: Choose ONE per project

Pick one and use it consistently everywhere. Do not mix approaches.

**Recommended options (pick one):**
- **Riverpod** — for new projects, most flexible
- **Bloc/Cubit** — for large team projects, strict pattern
- **Provider** — for simple projects

### State Structure

Every piece of async state follows this pattern:

```dart
class UserState {
  final bool isLoading;
  final String? error;
  final UserModel? data;

  const UserState({
    this.isLoading = false,
    this.error,
    this.data,
  });

  // copyWith — MANDATORY for immutable state updates
  UserState copyWith({
    bool? isLoading,
    String? error,
    UserModel? data,
    bool clearError = false,   // MANDATORY — the only way to erase an error
  }) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      data: data ?? this.data,
    );
  }
}
```

**Why `clearError`:** without it, `copyWith(isLoading: true)` silently wipes an existing
error message and the user never sees it. Error must change ONLY when you say so.

```dart
state = state.copyWith(isLoading: false, error: 'Wrong password'); // set error
state = state.copyWith(isLoading: true);                           // error preserved
state = state.copyWith(isLoading: true, clearError: true);          // error erased
```

Every nullable field in every state class follows this pattern — a `clearX` flag, never
bare assignment.

### When to Use What

```
Local state (setState):
  - Show/hide toggles, expansion state, selected tab
  - Animation controllers
  - TextEditingController itself needs NO setState — only call setState if the UI
    outside the field must react to typing
  - Simple toggle (show/hide password)
  - Tab selection
  — Rule: if state dies with the widget, use local

Global state (Riverpod/Bloc/Provider):
  - User session / auth status
  - Data from API
  - App theme
  - Cart / selections that persist across screens
  — Rule: if state survives navigation, use global
```

### Rules

```
- UI reads state and dispatches events — nothing else
- Controller/Bloc processes events and emits new state — nothing else
- NEVER modify state directly from widget
- NEVER call API from state management layer — call repository
- Handle loading, success, error in EVERY async operation
- Dispose controllers/streams when widget is disposed
- ALWAYS use copyWith for state updates — never create new state manually
- Clearing a nullable field (error, data) requires an explicit clearX flag — never rely
  on passing null
```

---

## 5. API & Data Layer

### Flow

```
Widget → Controller → Repository → Service → API
  UI        Logic       Source       HTTP     Server

Data flows back:
API → Service → Repository → Controller → Widget
JSON   Raw       Model        State       UI
```

### Service (HTTP calls)

```
- One service per API domain (UserService, OrderService)
- Returns raw API response — no business logic
- Uses api_client.dart for HTTP — never creates its own Dio instance
- Every method has try/catch — throws custom exceptions
```

### Repository (data source)

```
- One repository per domain (UserRepository, OrderRepository)
- Implements abstract interface from core/interfaces/
- Decides: fetch from API or return cached data?
- Converts raw response → Model
- Widget/controller NEVER knows if data came from API or cache
```

### Model (data class)

```
- One model per API entity
- fromJson() and toJson() methods (use json_serializable or freezed)
- Immutable — all fields final
- No business logic inside models
- part directive for generated code: part 'user_model.g.dart';
```

### Pagination Pattern

```dart
// Standard pagination response
class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasNextPage;

  const PaginatedResponse({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasNextPage,
  });

  // Generic models cannot be code-generated — pass the item parser explicitly
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) itemFromJson,
  ) {
    return PaginatedResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => itemFromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['total_count'] as int,
      currentPage: json['current_page'] as int,
      totalPages: json['total_pages'] as int,
      hasNextPage: json['has_next_page'] as bool,
    );
  }
}

// Usage:
// PaginatedResponse.fromJson(response.data, UserModel.fromJson)

// Usage — pick ONE approach per project, use consistently:
// Option A — Offset-based: ?page=2&limit=20
// Option B — Cursor-based: ?cursor=abc123&limit=20

// NEVER mix offset and cursor in same project
```

### Error Handling

```
Service:      throws typed exceptions from core/errors/exceptions.dart (see Section 7)
Repository:   catches exceptions → falls back to cache, or rethrows. NEVER swallows
Controller:   catches failures → updates state with error message
Widget:       reads state.error → shows user-friendly message

NEVER show raw error to user ("SocketException: OS Error")
ALWAYS show friendly message ("Unable to connect. Please check your internet.")
```

### API Client Rules

```
- Base URL from environment config — never hardcoded
- Auth token added via interceptor (api_interceptors.dart) — never manually per request
- Timeout: connect 10s, receive 30s
- Retry: 3 attempts for network errors on IDEMPOTENT requests only (GET, HEAD, PUT, DELETE)
- NEVER retry POST — creates duplicate orders, payments, messages
- 0 retries for any 4xx — the request itself is wrong, repeating won't fix it
- Log requests in debug mode only, never in release
```

---

## 6. Logger — MANDATORY (Never Use print)

### Rule

```
NEVER use print(), debugPrint(), or stdout in any code.
ALWAYS use the app Logger from core/utils/logger.dart.
This rule has ZERO exceptions.

NEVER log tokens, passwords, OTPs, emails, phone numbers, addresses, or payment data —
not even in debug. Log IDs instead: 'user 4f2a login failed', never the email.

AppLogger.error MUST forward to a crash reporter in release mode. dev.log output is
invisible in production — an error nobody can read is not error handling.
```

### Logger Implementation (core/utils/logger.dart)

```dart
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      dev.log('💚 [DEBUG] ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      dev.log('💙 [INFO] ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      dev.log('🟡 [WARN] ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    dev.log(
      '🔴 [ERROR] ${tag != null ? '[$tag] ' : ''}$message',
      error: error,
      stackTrace: stackTrace,
    );
    // TODO: Add crash reporting (Sentry/Firebase Crashlytics) for release mode
    // if (kReleaseMode) { CrashReporting.recordError(error, stackTrace); }
  }
}
```

### Usage

```dart
// CORRECT
AppLogger.debug('User loaded', tag: 'UserRepo');
AppLogger.info('Login successful', tag: 'Auth');
AppLogger.warning('Cache miss for user $id', tag: 'Cache');
AppLogger.error('Failed to fetch user', tag: 'UserService', error: e, stackTrace: st);

// WRONG — NEVER DO THIS
print('User loaded');
debugPrint('Login successful');
stdout.writeln('something');
```

### Log Levels

```
debug:    Development only — variable values, flow tracking. Stripped in release.
info:     Important events — login, navigation, data loaded. Stripped in release.
warning:  Something unexpected but recoverable — cache miss, retry, fallback. Debug only.
error:    Something failed — API error, parse failure. Logs in ALL modes. Send to crash reporter in release.
```

---

## 7. Error Handling Pattern

### Exception Classes (core/errors/exceptions.dart)

```
- ServerException        — API returned 5xx
- UnauthorizedException  — API returned 401/403
- NotFoundException      — API returned 404
- NetworkException       — No internet / connection failed
- ApiTimeoutException    — Request timed out
- CacheException         — Local storage read/write failed
- ValidationException    — Input validation failed

This list is the SINGLE source of truth. Every layer uses these names, nothing else.

NEVER name a custom exception `TimeoutException` — that name already exists in
`dart:async`, and importing both breaks the build. Hence `ApiTimeoutException`.

ONE error style only: typed exceptions, thrown and caught. Do NOT add a `Failure` /
`Either` / `Result` layer on top — two styles doing the same job means two classes and a
converter for every error, with zero benefit.
```

### Error Flow

```
Service layer:
    try {
      response = await apiClient.get('/users');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw UnauthorizedException();
      if (e.response?.statusCode == 404) throw NotFoundException();
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) throw ApiTimeoutException();
      if (e.type == DioExceptionType.connectionError) throw NetworkException();
      throw ServerException();
    }

Repository layer:
    try {
      final data = await userService.getUser(id);
      return UserModel.fromJson(data);
    } on NetworkException {
      return await localCache.getUser(id);
    }

Controller layer:
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await userRepository.getUser(id);
      state = state.copyWith(isLoading: false, data: user);
    } on UnauthorizedException {
      state = state.copyWith(isLoading: false, error: 'Session expired. Please login again.');
    } on NetworkException {
      state = state.copyWith(isLoading: false, error: 'No internet connection.');
    } on ApiTimeoutException {
      state = state.copyWith(isLoading: false, error: 'Request timed out. Try again.');
    } catch (e) {
      AppLogger.error('Unexpected error', error: e);
      state = state.copyWith(isLoading: false, error: 'Something went wrong. Please try again.');
    }

Widget layer:
    if (state.error != null) {
      return ErrorDisplay(message: state.error!);
    }
```

### Rules

```
- EVERY async call must have try/catch
- Service throws typed exceptions — never generic Exception
- Controller converts exceptions to user-friendly strings
- Widget only reads state.error — never catches exceptions
- Log every error with AppLogger.error() — never swallow silently
- Never show stack traces or technical errors to user
- Message TEXT comes from l10n, not hardcoded strings (see Section 21) — the plain
  strings in the examples above are shorthand for l10n keys
```

---

## 8. Navigation & Routing

### Router Choice

Use GoRouter (recommended) or auto_route. Pick ONE. Never use Navigator.push() directly.

### Route Definition

```
All routes defined in ONE file: app/routes.dart

Route patterns (used by the router definition only):
  static const login = '/login';
  static const home = '/home';
  static const settings = '/settings';
  static const userProfilePattern = '/user/:id';

Path builders (used by widgets — never string-concat a path in a widget):
  static String userProfile({required String id}) => '/user/$id';
  static String search({required String query}) => '/search?q=$query';
```

### Rules

```
- All routes in one file — never scatter across features
- Use named routes — never hardcode path strings in widgets
- Route guards for protected screens (auth check)
- Pass data via path parameters (/user/123) or query parameters (/search?q=flutter)
- NEVER pass complex objects via navigation — pass ID, fetch from repository
- Deep linking must work — every screen reachable via URL
- Handle unknown routes — show 404 page
- Back navigation must always work — never break the back stack
```

### Navigation from Widget

```
CORRECT:
  context.go(Routes.home);
  context.push(Routes.userProfile(id: '123'));

WRONG:
  Navigator.push(context, MaterialPageRoute(builder: (_) => HomeScreen()));
  context.go('/home');  // hardcoded string — use constant
```

---

## 9. Dependency Injection

### Pattern

Services and repositories must be provided — never created inside widgets.

```
CORRECT:
  final userRepo = ref.watch(userRepositoryProvider);

WRONG:
  final service = UserService(Dio());  // creates new instance every rebuild
```

### Rules

```
- Core dependencies (api client, services, repositories) registered in ONE file:
  app/injection.dart
- Feature controllers/providers may live in their own feature folder, but must be
  exported from injection.dart so there is still one place to look
- Services created ONCE at app startup — singleton
- Repositories created ONCE — singleton, depend on injected services
- Controllers created per feature/screen — depend on injected repositories
- Widgets NEVER create services or repositories
- Use Riverpod providers / GetIt / Provider for injection — pick ONE
```

### Hierarchy

```
API Client (singleton — one instance)
    ↓
Services (singleton — one per domain)
    ↓
Repositories (singleton — one per domain, depends on services)
    ↓
Controllers (per screen — depends on repositories)
    ↓
Widgets (reads from controllers)
```

---

## 10. Git & Commit Rules

### Who Does What

```
Claude WRITES code, runs the verification checklist, and PUSHES when asked.
Claude NEVER runs git add or git commit — it only writes the commit MESSAGE as text.
The user stages and commits. Always.
```

### Verification Checklist — RUN EVERY TIME BEFORE PUSH

```bash
# Step 1: If any annotated class changed (@JsonSerializable / @freezed / @riverpod)
#         regenerate FIRST — analyze and test both read generated code
dart run build_runner build --delete-conflicting-outputs

# Step 2: Remove unused imports and apply fixes
dart fix --apply

# Step 3: Format all files
dart format .

# Step 4: Analyze — MUST be zero warnings
flutter analyze --fatal-infos --fatal-warnings

# Step 5: Run tests — MUST all pass
flutter test
```

**DO NOT push if any step fails.** Fix the cause, then run the whole checklist again
from Step 1. Fixes create new uncommitted changes, so STOP and let the user commit them
before pushing.

### Commit Message Format

Claude's only job here is to produce this text. Present it in a copyable block and stop:

```
feat(auth): add login screen with email validation
```


```
type(scope): short description

Types:
  feat     — new feature
  fix      — bug fix
  refactor — code change that doesn't add feature or fix bug
  style    — formatting, missing semicolons (no code change)
  test     — adding or fixing tests
  docs     — documentation changes
  chore    — build process, dependency updates

Examples:
  feat(auth): add login screen with email validation
  fix(chat): resolve SSE connection timeout
  refactor(user): extract profile widget into separate file
  test(auth): add unit tests for login controller

WRONG:
  updated code
  fix
  changes
  WIP
```

### .gitignore — NEVER Commit These

```
# Generated code — CI MUST run build_runner before analyze/test (see Section 24)
*.g.dart
*.freezed.dart
*.mocks.dart          # only produced by mockito; mocktail needs no codegen

# Build outputs
build/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies

# Environment — see Section 23
.env
.env.local
.env.production
# .env.example IS committed — template with empty values

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db

# Coverage
coverage/
```

### Rules

```
- ONE commit = ONE logical change — don't mix unrelated changes
- NEVER push directly to main — use feature branches
- Branch naming: feature/login-screen, bugfix/null-crash, hotfix/api-timeout
- Claude never stages, commits, amends, rebases, resets, or force-pushes
- Claude may run: git status, git diff, git log, git branch (read-only, no approval needed)
- If the working tree is dirty when the user says "push", STOP and say so — never
  commit the leftovers to make the push work
```

### Push Flow — ALWAYS Follow This Order

```
1. Write code → show it → STOP

2. User says "commit"
   → output the commit message text only
   → STOP. The user runs git add and git commit.

3. User says "push"
   → Step A: run the verification checklist above (all 5 steps, in order)
   → Step B: if ANY step fails:
              - fix the cause
              - show what changed
              - output a new commit message
              - STOP. User commits the fix. Do not push yet.
   → Step C: if everything passes, check the tree is clean: git status
              - dirty tree → STOP, tell the user what is uncommitted
   → Step D: git pull origin <branch>
   → Step E: conflicts? → STOP → show them → ask how to resolve.
              User resolves AND commits the merge. Claude does neither.
   → Step F: no conflicts → git push

NEVER push without running the verification checklist first.
NEVER push without pulling first.
NEVER auto-resolve merge conflicts.
NEVER force push — that is on the NEVER list even with approval.
```

---

## 11. Dependencies Rule

```
DO NOT add any package without user approval.
Before adding any dependency — ask first.
Check pubspec.yaml for currently approved packages.
```

---

## 12. Code Generation Rules

### When to Run build_runner

```
Run after ANY of these changes:
- Created or modified a model with @JsonSerializable
- Created or modified a class with @freezed
- Created or modified a class with @riverpod
- Created or modified mock annotations for tests

Command:
  dart run build_runner build --delete-conflicting-outputs
```

### Rules

```
- NEVER manually edit .g.dart or .freezed.dart files
- NEVER commit generated files
- ALWAYS run build_runner after modifying annotated classes
- Add part directive: part 'user_model.g.dart';
- build_runner goes in dev_dependencies, not dependencies
```

---

## 13. Null Safety Rules

### Prefer Safe Access

```
CORRECT:
  final name = user?.name ?? 'Unknown';
  if (user != null) { doSomething(user); }

WRONG:
  final name = user!.name;           // crashes if null
```

### When to Use Each

```
?   (nullable type)     — when value CAN be null: String? name;
??  (null coalescing)   — provide default: name ?? 'Unknown'
?.  (null-aware access) — safe access: user?.name
!   (force unwrap)      — ONLY after explicit null check in same scope
late (late init)        — ONLY for: DI, animation controllers in initState
required               — when parameter MUST be provided
```

### Rules

```
- Prefer non-nullable types — String not String?
- Make fields nullable ONLY when they genuinely can be null
- NEVER use ! on API response data
- If you need ! more than twice in a function — rethink null handling
```

---

## 14. Async Patterns

### Use async/await — Not .then()

```
CORRECT:
  Future<void> loadUser() async {
    try {
      final user = await userRepository.getUser(id);
      state = state.copyWith(data: user);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load');
    }
  }

WRONG:
  void loadUser() {
    userRepository.getUser(id).then((user) { ... }).catchError((e) { ... });
  }
```

### Rules

```
- async/await always — never .then() chains
- After EVERY await, check the widget is still alive before touching context or state:
    if (!mounted) return;              // State / StatefulWidget
    if (!ref.mounted) return;          // Riverpod notifier
  Skipping this is the most common crash in Flutter apps
- StreamSubscription stored as field and cancelled in dispose()
- Never fire-and-forget without error handling
- Debounce rapid calls (search input)
- Cancel ongoing requests when widget disposes
```

---

## 15. Annotations & Parameters

### Required Annotations

```
@override             — ALWAYS when overriding (build, dispose, initState)
@immutable            — on state and config value classes (widgets are already immutable)
@protected            — on methods only for subclasses
@visibleForTesting    — on methods exposed only for testing
const                 — on constructors that can be const
```

### Parameter Rules

```
- Use named parameters for widgets: AppButton(label: 'Submit', onPressed: _handle)
- Use required for must-have params: required this.userId
- Use default values for optional: this.isEnabled = true
- Mark fields as final — always
```

---

## 16. File Creation Rules

### When to Create New File

```
- New widget → new file
- New model → new file
- New service → new file
- File exceeds 300 lines → split
```

### When NOT to Create New File

```
- Small private helper widget → keep as private class in same file
- Enum with 3-5 values for one model → keep in model file
- One utility function → add to existing utils file
```

### File Placement

```
Used by ONE feature     → inside that feature's folder
Used by 2+ features     → shared/ folder
Used by data layer only → data/ folder
Used everywhere         → core/ folder
```

---

## 17. Comment Rules

### Write Comments For

```
- Public API docs: /// doc comments on public classes, methods
- Complex business logic: WHY, not WHAT
- Workarounds with explanation
- TODO with ticket: // TODO(JIRA-123): Refactor after API v2
```

### Do NOT Write Comments For

```
- Obvious code: // increment counter
- Closing braces: // end of if
- Section headers in small files
```

### Format

```dart
/// Fetches user profile from API.
///
/// Returns [UserModel] if found.
/// Throws [NotFoundException] if user does not exist.
Future<UserModel> getUser(String id) async { ... }
```

### Rules

```
- /// for public API docs, // for inline
- Comments explain WHY — code explains WHAT
- No commented-out code — delete it
- No TODO without ticket number
```

---

## 18. Command Reference

### Build Modes

```bash
flutter run --debug        # Default. Hot reload. Assertions ON. Slow. For development.
flutter run --profile      # Performance testing. Near-release speed. For finding jank.
flutter run --release      # Production. No debug. Full optimization. For testing real UX.
```

### Build with Parameters

```bash
# Android
flutter build apk --release                        # Universal APK
flutter build apk --split-per-abi --release         # Split by architecture — smaller files
flutter build appbundle --release                   # AAB for Play Store
flutter build apk --obfuscate --split-debug-info=build/debug-info --release  # Obfuscated release

# iOS
flutter build ipa --release                         # IPA for App Store

# Web — the --web-renderer flag is REMOVED. Never use it. CanvasKit is the default.
flutter build web --release                         # Standard build (CanvasKit)
flutter build web --wasm --release                  # WebAssembly — faster, modern browsers

# Version
flutter build apk --build-name=1.2.3 --build-number=42 --release
```

### Format with Parameters

```bash
dart format .                          # Format all files
dart format --set-exit-if-changed .    # Fails if unformatted — use in CI
dart format -o none .                  # Dry run — show what WOULD change
```

### Analyze with Parameters

```bash
flutter analyze                                 # Standard
flutter analyze --fatal-infos --fatal-warnings  # Strictest — any warning = failure. Use in CI.
```

### Test with Parameters

```bash
flutter test                                    # All tests
flutter test test/unit/                         # Only unit tests
flutter test --name="should return user"        # Match test name
flutter test --coverage                         # Generate coverage report
flutter test --update-goldens                   # Update golden images
```

### build_runner

```bash
dart run build_runner build --delete-conflicting-outputs   # Generate once. ALWAYS use --delete-conflicting-outputs
dart run build_runner watch --delete-conflicting-outputs   # Watch mode — auto-regenerate on file change
dart run build_runner clean                                # Delete all generated files — use when broken
```

---

## 19. Test Rules

### Folder Structure

```
test/
├── unit/              # Services, repositories, controllers, models
├── widget/            # Screens, widgets
├── integration/       # Full user flows
└── mocks/             # Shared mock classes
```

### Naming

```
Source file                              → Test file
lib/data/services/auth_service.dart      → test/unit/auth_service_test.dart
lib/data/repositories/auth_repository.dart → test/unit/auth_repository_test.dart
lib/features/auth/controllers/auth_controller.dart → test/unit/auth_controller_test.dart
lib/features/auth/screens/login_screen.dart → test/widget/login_screen_test.dart
lib/data/models/user_model.dart          → test/unit/user_model_test.dart
```

### What MUST Have Tests

```
Every service       → unit test (MANDATORY)
Every repository    → unit test (MANDATORY)
Every controller    → unit test (MANDATORY)
Every screen        → widget test (MANDATORY)
Every model         → unit test for fromJson/toJson (MANDATORY)
Integration tests   → critical flows only (login, payment, signup) — when user asks
```

### Test Structure — Arrange, Act, Assert

```dart
test('should return user when login succeeds', () async {
  // Arrange — setup mock data
  when(() => mockService.login(email: 'test@mail.com', password: '123'))
      .thenAnswer((_) async => mockLoginResponse);

  // Act — call the function being tested
  final result = await repository.login(email: 'test@mail.com', password: '123');

  // Assert — check the result
  expect(result.user.email, 'test@mail.com');
  expect(result.token, isNotEmpty);
  verify(() => mockService.login(email: 'test@mail.com', password: '123')).called(1);
});

test('should throw UnauthorizedException when login fails', () async {
  // Arrange
  when(() => mockService.login(email: any(named: 'email'), password: any(named: 'password')))
      .thenThrow(UnauthorizedException());

  // Act & Assert
  expect(
    () => repository.login(email: 'wrong@mail.com', password: 'wrong'),
    throwsA(isA<UnauthorizedException>()),
  );
});
```

### Mock Rule

```
- Use mocktail (recommended — no code generation) OR mockito (needs build_runner and
  produces *.mocks.dart). Pick ONE per project, never both
- Mock EXTERNAL dependencies (API client, services, storage) — never mock the thing being tested
- Shared mocks go in test/mocks/ — reuse across tests
- Mock class naming: MockAuthService, MockUserRepository (Mock prefix)
```

### MANDATORY Rule

```
Files that MUST have a test — no exception:
  services, repositories, controllers, models, screens, mixins, validators, formatters,
  extensions with logic
When Claude creates auth_service.dart → MUST also create auth_service_test.dart.

Files that are EXEMPT (a test would only restate the code):
  routes.dart, theme.dart, theme_extensions.dart, constants.dart, api_endpoints.dart,
  env.dart, injection.dart, enum-only files, barrel/export files, generated *.g.dart /
  *.freezed.dart, everything inside test/mocks/

Tests must pass before push (verification checklist: flutter test).
```

### Code-Test Sync — ALWAYS Stay In Sync

```
Add function    → add its test
Update function → update its test
Delete function → delete its test
Rename function → rename its test
Delete file     → delete its test file
Rename file     → rename its test file
Move file       → move its test file

Code changes = test changes. ALWAYS. No orphan tests. No untested code.
```

---

## 20. Lint & Static Analysis — MANDATORY

Rules a human has to remember get broken. Rules a linter enforces do not.
`analysis_options.yaml` must exist at the project root before any code is written.

### analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-raw-types: true
  errors:
    avoid_print: error                      # print() becomes a build failure
    use_build_context_synchronously: error   # missing mounted check = failure
    unused_import: error
    missing_required_param: error
    todo: ignore
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    - always_declare_return_types
    - avoid_dynamic_calls
    - avoid_print
    - cancel_subscriptions
    - close_sinks
    - prefer_const_constructors
    - prefer_const_constructors_in_immutables
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_final_locals
    - prefer_single_quotes
    - require_trailing_commas
    - sort_child_properties_last
    - unawaited_futures
    - unnecessary_this
    - use_super_parameters
```

### Rules

```
- flutter analyze --fatal-infos --fatal-warnings MUST pass with zero output
- NEVER silence a warning to make the build pass — fix the cause
- // ignore: requires a reason comment on the line directly above:
    // Dio returns dynamic here; shape is validated in fromJson
    // ignore: avoid_dynamic_calls
- // ignore_for_file: is banned except in generated files
- Adding or relaxing a lint rule needs user approval — it changes the whole codebase
```

### Not lint-enforceable — manual review

```
The 300-line file limit, 50-line build() limit and 3-level nesting limit (Sections 3, 16)
have no built-in lint. Claude checks them by reading the file before every push.
A metrics package (dart_code_metrics) could automate this — requires user approval first.
```

---

## 21. User-Facing Strings (English only)

### Rule

```
EVERY string a user can read lives in lib/l10n/app_en.arb. No exceptions.
This project is English only — ONE .arb file. Do not add other languages unless the
user asks.

Dart constants hold only non-visible strings: API paths, storage keys, asset paths,
analytics event names.

Why an .arb file and not a plain AppStrings class: same effort, but the generated
lookup gives you compile-safe keys, typed placeholders, and correct plural/date
handling from intl. Adding a second language later becomes a new file, not a rewrite.
```

### Setup

```yaml
# pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

### ARB File

The key IS the English text, written in camelCase. No invented prefixes, no guessing —
read the key, you know the string.

```json
{
  "logIn": "Log in",
  "noInternetConnection": "No internet connection.",
  "sessionExpiredPleaseLogInAgain": "Session expired. Please log in again.",
  "helloName": "Hello, {name}",
  "@helloName": {
    "placeholders": { "name": { "type": "String" } }
  }
}
```

Keys become generated Dart method names, so they must be valid identifiers:
starts with a lowercase letter, letters and digits only.

```
"Log in"                  ❌ space — code generation fails
"No internet connection." ❌ space and period — fails
"logIn"                   ✅
"noInternetConnection"    ✅
```

Long sentence → strip punctuation, keep the meaningful words, drop filler:

```
"Your order has been placed successfully."  →  "orderPlacedSuccessfully"
"Are you sure you want to delete this?"     →  "confirmDelete"
```

Placeholders: the key uses the placeholder NAME, not the braces —
`"Hello, {name}"` becomes `helloName`.

### Usage

```dart
// CORRECT
Text(AppLocalizations.of(context)!.logIn)
Text(context.l10n.helloName(user.name))    // via context_extensions.dart

// WRONG
Text('Log in')
const kLoginLabel = 'Log in';
```

### Error Messages

```
Controller stores an error CODE, widget resolves the text:

  // controller
  } on NetworkException {
    state = state.copyWith(isLoading: false, error: AppError.noInternet);
  }

  // widget
  ErrorDisplay(message: context.l10n.messageFor(state.error!))

This keeps display text out of the logic layer. Plain message strings in the controller
are tolerated for speed, but the text itself MUST come from app_en.arb — never from
string literals scattered across widgets.
```

### Rules

```
- Key naming: camelCase of the English text itself — 'Log in' → logIn,
  'No internet connection.' → noInternetConnection. NEVER invent an unrelated key name
- Same text used in two places = ONE key, reused. Never duplicate a string under two keys
- Text changed but meaning is the same → keep the old key, just edit the value
- Text meaning changed → new key, delete the old one
- NEVER build a sentence by concatenating translated pieces — use placeholders
- app_en.arb is the only string file — never create a second one, never hardcode
- Dates, numbers, currency go through formatters.dart (intl), never manual string math
- Run flutter gen-l10n (or flutter pub get) after editing app_en.arb
```

---

## 22. Theme & Responsive Rules

### Rule

```
No color, size, spacing, radius, or text style is ever written inline in a widget.
Everything comes from Theme.of(context) or a ThemeExtension.
```

### Spacing Scale — Only These Values

```
4, 8, 12, 16, 24, 32, 48

const SizedBox(height: 16)        ✅
const SizedBox(height: 17)        ❌ off-scale
EdgeInsets.all(context.space.md)  ✅ via ThemeExtension
```

### ThemeExtension for App-Specific Tokens

```dart
// config/theme_extensions.dart
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({required this.sm, required this.md, required this.lg});

  final double sm;
  final double md;
  final double lg;

  @override
  AppSpacing copyWith({double? sm, double? md, double? lg}) =>
      AppSpacing(sm: sm ?? this.sm, md: md ?? this.md, lg: lg ?? this.lg);

  @override
  AppSpacing lerp(AppSpacing? other, double t) => other ?? this;
}
```

### Breakpoints (core/utils/responsive.dart)

```
mobile   < 600
tablet   600 – 1023
desktop  >= 1024

Read via context extension: context.isMobile, context.isTablet
NEVER call MediaQuery.of(context).size.width directly inside a widget tree
```

### Rules

```
- Light AND dark ThemeData both defined in theme.dart — dark mode is not optional
- NEVER branch on Theme.of(context).brightness in a widget — define the colour in both
  themes and just read it
- Text styles: Theme.of(context).textTheme.bodyMedium — never TextStyle(fontSize: 16)
- Colors: Theme.of(context).colorScheme.primary — never Color(0xFF...) in a widget
- Asset paths as constants: AppAssets.loginBg — never 'assets/images/login_bg.png' inline
- One responsive layout widget (shared/layouts/responsive_layout.dart) — do not scatter
  width checks across screens
```

---

## 23. Environment & Secrets

### Rule

```
Config values are loaded at runtime from a .env file with flutter_dotenv.
.env is bundled as an asset and is NEVER committed — only .env.example is.

Because .env ships inside the app bundle, a released binary is readable by anyone.
.env therefore holds ONLY non-sensitive config: base URLs, feature flags, public
DSNs. NEVER a private key or admin secret — those belong on your server.
```

### .env (gitignored)

```
ENV=dev
API_BASE_URL=https://dev-api.example.com
SENTRY_DSN=https://...
ENABLE_LOGGING=true
```

`.env.example` IS committed — same keys, empty values, so a new developer knows what
to fill in. First-run setup: `cp .env.example .env` and fill it in.

### pubspec.yaml — bundle .env as an asset

```yaml
dependencies:
  flutter_dotenv: ^5.1.0

flutter:
  assets:
    - .env
```

### config/env.dart

`flutter_dotenv` reads at runtime, so values are getters — NOT compile-time `const`.
Guard every read with `dotenv.isInitialized` so tests (which never call
`dotenv.load`) do not throw `NotInitializedError`.

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class Env {
  const Env._();

  static String _raw(String key) =>
      dotenv.isInitialized ? (dotenv.env[key] ?? '') : '';

  static String get apiBaseUrl => _raw('API_BASE_URL');
  static bool get enableLogging => _raw('ENABLE_LOGGING') == 'true';

  static bool get isConfigured => apiBaseUrl.isNotEmpty;
}
```

### Load at startup (main.dart)

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(); // defaults to '.env'
  assert(Env.isConfigured, 'Missing .env config. Copy .env.example to .env.');
  runApp(const KidunaApp());
}
```

### Commands

```bash
flutter run                        # reads the bundled .env — no extra flags
flutter build apk --release        # .env for the target env must be in place first
```

### Rules

```
- NEVER hardcode a base URL, key, or DSN anywhere in lib/ — read it via Env
- NEVER put a private key or admin secret in .env — it ships in the bundle, readable
  by anyone. Those belong on your server
- Env values are runtime getters (dotenv), NOT const — guard reads with
  dotenv.isInitialized, do not wrap them in a provider
- Call `await dotenv.load()` (defaults to '.env') before runApp, then assert
  Env.isConfigured so a missing or empty .env fails loudly, not silently
- Adding a new env key = update .env, .env.example, and env.dart
```

---

## 24. CI Pipeline

Generated files are gitignored (Section 10), so CI MUST regenerate them before it can
analyze or test anything.

### Required steps, in this order

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
```

### Rules

```
- CI runs on every pull request — no merge while it is red
- main branch is protected: no direct push, PR only (Section 10)
- Same commands as the verification checklist — CI must never be laxer than local
- Claude NEVER triggers CI/CD or deploys without explicit user approval (Approval Rule)
- Config comes from the CI provider's secret store, written to .env at build time —
  never committed
```

---

## 25. Do's and Don'ts

### DO

```
✅ Use const constructors wherever possible
✅ Use final for variables that don't change
✅ Write descriptive names (see Section 2)
✅ Handle null safely — prefer ?? and ?. over ! (see Section 13)
✅ Dispose controllers, StreamSubscriptions, AnimationControllers, TextEditingControllers
✅ Use ListView.builder() for dynamic lists
✅ Use const EdgeInsets, const SizedBox
✅ Run the verification checklist before every push (see Section 10)
✅ Specify types explicitly — List<String> not var or dynamic
✅ Use enums instead of string constants
✅ Use named parameters for widgets
✅ Use Theme.of(context) — never hardcode colors/sizes/text styles
✅ Use AppLogger — never print() (see Section 6)
✅ Write the commit message and hand it over — never run git commit (see Section 10)
✅ Use copyWith for state updates, with clearError to erase errors (see Section 4)
✅ Check if (!mounted) return; after every await before using context or state (Section 14)
✅ Put every user-facing string in an .arb file (see Section 21)
✅ Keep analysis_options.yaml green — zero infos, zero warnings (see Section 20)
```

### DON'T

```
❌ Don't use print(), debugPrint(), or stdout (see Section 6)
❌ Don't hardcode strings, colors, sizes, API URLs — use constants/theme/config
❌ Don't ignore lint warnings — fix every one
❌ Don't use dynamic type — always specify types
❌ Don't nest widgets more than 3 levels — extract (see Section 3)
❌ Don't put logic in build() — move to controller
❌ Don't use setState beyond simple local toggles (see Section 4)
❌ Don't catch exceptions silently — always log (see Section 7)
❌ Don't commit generated files, .env, debug code (see Section 10)
❌ Don't commit commented-out code or TODO without ticket
❌ Don't run git add, git commit, or git push --force — ever (see Section 10)
❌ Don't push without running the verification checklist first (see Section 10)
❌ Don't use ! without prior null check (see Section 13)
❌ Don't create God widgets — one widget = one job
❌ Don't mix material.dart and cupertino.dart in same file — use .adaptive constructors
❌ Don't store sensitive data in SharedPreferences — use flutter_secure_storage
❌ Don't add packages without user approval (see Section 11)
❌ Don't use "Page" — always "Screen" (see Section 2)
❌ Don't use Navigator.push — use GoRouter (see Section 8)
❌ Don't create services/repos inside widgets — use DI (see Section 9)
❌ Don't hardcode user-facing text in Dart — use l10n (see Section 21)
❌ Don't use context or state after an await without a mounted check (see Section 14)
❌ Don't name a class TimeoutException — clashes with dart:async (see Section 7)
❌ Don't add a Failure / Either layer — exceptions only (see Section 7)
❌ Don't retry POST requests on failure (see Section 5)
❌ Don't log tokens, emails, phone numbers, or any PII (see Section 6)
❌ Don't use --web-renderer — the flag no longer exists (see Section 18)
❌ Don't write // ignore: without a reason comment on the line above (see Section 20)
```