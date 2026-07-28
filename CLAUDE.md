# RULES — MANDATORY — NO EXCEPTIONS

You MUST follow every rule in this document.
Before writing ANY code, re-read the relevant section.
Before EVERY commit, follow the pre-commit checklist in Section 11.
If unsure, ask — do not guess.
Violation of these rules is considered a bug.

## APPROVAL RULE

```
NEVER auto-execute repository-changing actions. WAIT for user approval.

AUTO-RUN OK (no approval needed):
  - dart format .
  - flutter analyze
  - flutter test
  - dart run build_runner build
  - flutter pub get

APPROVAL REQUIRED (user must explicitly say):
  - git add / git commit / git push
  - Create / merge / delete branch
  - Create pull request
  - Install/remove packages (flutter pub add/remove)
  - Delete files
  - Deploy anything
  - Any CI/CD trigger

EXACT APPROVAL WORDS:
  "commit" → then commit
  "push" → then push
  "deploy" → then deploy
  "add package X" → then add
  "delete" → then delete

  "looks good", "ok", "nice", "sure" = NOT approval to commit/push/deploy.
  If unsure → ASK: "Should I commit this?"

WORKFLOW:
  1. User asks to write code → you WRITE code → STOP
  2. Show what you wrote and explain → STOP
  3. User reviews → gives next instruction
  4. User says "commit" → run pre-commit checklist → THEN commit
  5. No approval word = no action
```

---

# CLAUDE.md — Flutter Development Guide

This document is the single source of truth for Flutter development in this project. Follow these rules strictly. Do not deviate unless explicitly asked.

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
├── core/
│   ├── enums/                         # App-wide enums
│   │   ├── user_role.dart
│   │   └── order_status.dart
│   ├── errors/
│   │   ├── exceptions.dart            # Custom exception classes
│   │   └── failures.dart              # Failure classes for error handling
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
│   │   └── user_model.g.dart          # Generated — DO NOT edit, DO NOT commit
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
- Keep build() method under 50 lines — extract _buildSomething() private methods
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
  }) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      error: error,       // null clears the error
      data: data ?? this.data,
    );
  }
}
```

### When to Use What

```
Local state (setState):
  - Form input values
  - Animation controllers
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
}

// Usage — pick ONE approach per project, use consistently:
// Option A — Offset-based: ?page=2&limit=20
// Option B — Cursor-based: ?cursor=abc123&limit=20

// NEVER mix offset and cursor in same project
```

### Error Handling

```
Service:      throws ServerException, NetworkException, TimeoutException
Repository:   catches exceptions → returns Failure objects or rethrows
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
- Retry: 3 attempts for network errors, 0 for 4xx errors
- Log requests in debug mode only, never in release
```

---

## 6. Logger — MANDATORY (Never Use print)

### Rule

```
NEVER use print(), debugPrint(), or stdout in any code.
ALWAYS use the app Logger from core/utils/logger.dart.
This rule has ZERO exceptions.
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
- NetworkException       — No internet / timeout
- CacheException         — Local storage read/write failed
- ValidationException    — Input validation failed
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
      if (e.type == DioExceptionType.connectionTimeout) throw NetworkException();
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
```

---

## 8. Navigation & Routing

### Router Choice

Use GoRouter (recommended) or auto_route. Pick ONE. Never use Navigator.push() directly.

### Route Definition

```
All routes defined in ONE file: app/routes.dart

Route paths as constants:
  static const login = '/login';
  static const home = '/home';
  static const userProfile = '/user/:id';
  static const settings = '/settings';
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
- ALL dependencies registered in ONE file: app/injection.dart
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

### Pre-Commit Checklist — RUN EVERY TIME BEFORE COMMIT

```bash
# Step 1: Remove unused imports and apply fixes
dart fix --apply

# Step 2: Format all files
dart format .

# Step 3: Analyze — MUST be zero warnings
flutter analyze --fatal-infos --fatal-warnings

# Step 4: Run tests — MUST all pass
flutter test

# Step 5: If models changed — regenerate
dart run build_runner build --delete-conflicting-outputs
```

**DO NOT commit if any step fails.**

### Commit Message Format

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
# Generated code
*.g.dart
*.freezed.dart
*.mocks.dart

# Build outputs
build/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies

# Environment
.env
.env.local
.env.production

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
```

### Push Flow — ALWAYS Follow This Order

```
1. Write code
2. User says "commit" → run pre-commit checklist → commit
3. User says "push" → pull first: git pull origin <branch>
4. If conflicts found → STOP → show conflicts to user → ask how to resolve
5. NEVER auto-resolve conflicts — user decides
6. User resolves → commit merge → then push
7. No conflicts → push directly

NEVER push without pulling first.
NEVER auto-resolve merge conflicts.
NEVER force push (git push --force) without user explicitly saying "force push".
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
@immutable            — on widget classes
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

# Web
flutter build web --web-renderer canvaskit --release  # Full features, larger
flutter build web --web-renderer html --release       # Smaller, less features

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
- Use mocktail (recommended) or mockito for mocking
- Mock EXTERNAL dependencies (API client, services, storage) — never mock the thing being tested
- Shared mocks go in test/mocks/ — reuse across tests
- Mock class naming: MockAuthService, MockUserRepository (Mock prefix)
```

### MANDATORY Rule

```
Every code file MUST have a corresponding test file.
When Claude creates auth_service.dart → MUST also create auth_service_test.dart.
No code without test. No exception.
Tests must pass before commit (pre-commit checklist: flutter test).
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

## 20. Do's and Don'ts

### DO

```
✅ Use const constructors wherever possible
✅ Use final for variables that don't change
✅ Write descriptive names (see Section 2)
✅ Handle null safely — prefer ?? and ?. over ! (see Section 13)
✅ Dispose controllers, StreamSubscriptions, AnimationControllers, TextEditingControllers
✅ Use ListView.builder() for dynamic lists
✅ Use const EdgeInsets, const SizedBox
✅ Run pre-commit checklist before every commit (see Section 10)
✅ Specify types explicitly — List<String> not var or dynamic
✅ Use enums instead of string constants
✅ Use named parameters for widgets
✅ Use Theme.of(context) — never hardcode colors/sizes/text styles
✅ Use AppLogger — never print() (see Section 6)
✅ Follow commit message format (see Section 10)
✅ Use copyWith for state updates (see Section 4)
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
❌ Don't use ! without prior null check (see Section 13)
❌ Don't create God widgets — one widget = one job
❌ Don't mix material.dart and cupertino.dart in same file
❌ Don't store sensitive data in SharedPreferences — use flutter_secure_storage
❌ Don't add packages without user approval (see Section 11)
❌ Don't use "Page" — always "Screen" (see Section 2)
❌ Don't use Navigator.push — use GoRouter (see Section 8)
❌ Don't create services/repos inside widgets — use DI (see Section 9)
```
