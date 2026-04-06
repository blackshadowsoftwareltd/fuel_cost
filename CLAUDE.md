# Fuel Cost - Project Guide

## Overview

**Fuel Cost** is a Flutter mobile app for tracking fuel consumption, costs, and vehicle maintenance. Users log fuel fill-ups with odometer readings, and the app calculates mileage (km/L), tracks spending over time, and provides budgeting/comparison tools.

- **Package**: `com.blackshadowsoftwareltd.fuel_cost`
- **Version**: 1.0.0+3
- **Min SDK**: Dart ^3.8.1
- **Platforms**: Android, iOS (portrait-only)

## Architecture

### State Management
- **Riverpod** with mixed approach:
  - `fuel_entries_provider.dart`, `summary_providers.dart` use `@riverpod` annotations (code-gen, `.g.dart` files)
  - `theme_provider.dart`, `vehicle_provider.dart`, `maintenance_provider.dart` use plain Riverpod (no code-gen)
- **Important**: Running `build_runner` regenerates `.g.dart` files. The Isar `.g.dart` was pre-generated; there is no `isar_generator` in dev_dependencies.

### Database & Storage
- **Isar Community 3.3.0** (NoSQL embedded DB) for `FuelEntry` — the only Isar collection
- **SharedPreferences** for everything else:
  - Vehicles list, selected vehicle, entry-vehicle mapping
  - Maintenance entries
  - Theme mode, accent color
  - Currency selection
  - Monthly budget
  - Google Drive backup metadata

### Navigation
- `MaterialPageRoute` push/pop — no named routes, no router package

### Theming
- Material Design 3 with `ColorScheme.fromSeed()`
- Custom `ThemeService` builds light/dark themes with configurable accent color
- 10 preset accent colors, persisted in SharedPreferences

## Project Structure

```
lib/
  main.dart                          # App entry, ProviderScope + MaterialApp
  business_logic/
    fuel_calculations.dart           # Mileage metrics, efficiency chart data, total distance
  models/
    fuel_entry.dart + .g.dart        # Isar @collection (id, liters, pricePerLiter, totalCost, dateTime, odometerReading)
    vehicle.dart                     # Plain Dart class (id, name, iconName, fuelType, tankCapacity)
    maintenance_entry.dart           # Plain Dart class (id, vehicleId, type, description, cost, mileage, etc.)
  providers/
    fuel_entries_provider.dart + .g.dart   # @riverpod FuelEntries (AsyncNotifier)
    summary_providers.dart + .g.dart      # @riverpod totalCost, totalLiters, averageMileage, currency, etc.
    theme_provider.dart                   # Plain StateNotifier<ThemeState>
    vehicle_provider.dart                 # Plain FutureProvider/StateProvider for vehicles
    maintenance_provider.dart             # Plain FutureProvider for maintenance
  services/
    database_service.dart            # Singleton Isar instance with Completer guard
    fuel_storage_service.dart        # CRUD, mileage calc, CSV import/export
    vehicle_service.dart             # Vehicle CRUD + entry-vehicle mapping via SharedPreferences
    maintenance_service.dart         # Maintenance CRUD via SharedPreferences
    budget_service.dart              # Monthly budget + spending calculations
    theme_service.dart               # Theme mode + accent color persistence
    currency_service.dart            # 160+ currency symbols, persistence
    drive_backup_service.dart        # Google Sign-In + Google Drive appDataFolder backup/restore
    app_update_service.dart          # Google Play in-app update check (Android-only, via in_app_update)
  screens/
    home_screen.dart                 # Dashboard: quick stats, fuel chart, action buttons grid
    add_fuel_screen.dart             # Add/edit fuel entry with vehicle selector + mileage preview
    fuel_history_screen.dart         # Filterable fuel entry list with vehicle filter chips
    settings_screen.dart             # Currency, theme, budget, backup, CSV, data management
    trip_calculator_screen.dart      # Estimate trip fuel cost based on distance + avg mileage
    budget_report_screen.dart        # Monthly spending vs budget with FL Chart bar graphs
    spending_comparison_screen.dart  # Side-by-side 4-month spending comparison
    vehicle_comparison_screen.dart   # Per-vehicle cost, mileage, distance stats
    vehicle_management_screen.dart   # Add/edit/delete vehicles
    maintenance_log_screen.dart      # Add/view maintenance entries per vehicle
    how_to_use_screen.dart           # In-app usage guide
  widgets/
    widgets.dart                     # Barrel export for all widgets
    stat_card.dart                   # Stat display card (home)
    action_button.dart               # Grid action button (home)
    glass_text_field.dart            # Glassmorphism text input (add fuel)
    fuel_calculation_row.dart        # Key-value display row
    fuel_summary_card.dart           # Cost/mileage preview (add fuel)
    mileage_calculation_card.dart    # Detailed mileage breakdown
    fuel_entry_card.dart             # Swipeable entry card (history)
    fuel_summary_stats.dart          # Summary stats widget
    fuel_chart.dart                  # FL Chart line/bar chart
    fuel_chart_dashboard.dart        # Chart container with controls
    empty_state_widget.dart          # Empty state placeholder
    delete_confirmation_dialog.dart  # Delete confirm dialog
    confirmation_dialog.dart         # Generic confirm dialog
    currency_selection_dialog.dart   # Currency picker
    cupertino_section.dart           # iOS-style section (settings)
    cupertino_list_tile.dart         # iOS-style list tile (settings)
    staggered_animation_wrapper.dart # Staggered entrance animation
```

## Key Design Decisions

### Vehicle-Entry Mapping
Vehicle-to-fuel-entry mapping is stored in SharedPreferences as a JSON map (`entryId -> vehicleId`), NOT in the Isar schema. This avoids needing to regenerate the Isar `.g.dart` file.

### Mileage Calculation Logic
- Fuel at entry `i` is considered consumed between entry `i` and entry `i+1`
- Per-trip mileage: `(odometer[i+1] - odometer[i]) / liters[i]`
- Overall mileage: `totalDistance / (totalFuel - lastEntryFuel)` (last entry's fuel hasn't been consumed yet)
- Located in `lib/business_logic/fuel_calculations.dart`

### No build_runner for Isar
The `fuel_entry.g.dart` was pre-generated. Do NOT add `isar_generator` to dev_dependencies — it conflicts with other analyzer versions. If you modify the `FuelEntry` model, you must manually update the `.g.dart` or temporarily add the generator.

### Provider Code Generation
Only `fuel_entries_provider` and `summary_providers` use `@riverpod` code-gen. All newer providers (vehicle, theme, maintenance) use plain Riverpod to avoid the build_runner dependency chain.

## Features

1. **Fuel Tracking** - CRUD fuel entries with liters, price, odometer, vehicle assignment
2. **Mileage Calculation** - Automatic km/L calculation from odometer readings
3. **Multiple Vehicles** - Add vehicles with type/icon/fuel type/tank capacity; filter entries by vehicle
4. **Trip Cost Calculator** - Estimate fuel cost for a planned trip
5. **Budget & Reports** - Set monthly budget, view spending bar charts (FL Chart)
6. **Spending Comparison** - Compare 4 months side-by-side
7. **Vehicle Comparison** - Per-vehicle stats (cost, mileage, distance, cost/km)
8. **Maintenance Log** - Track 24 maintenance types with cost, mileage, next-due dates
9. **Google Drive Backup** - Sign in with Google, backup/restore CSV to Drive appDataFolder
10. **CSV Import/Export** - Share or import fuel data as CSV files
11. **Theme Customization** - Light/dark/system mode + 10 accent colors
12. **Currency Support** - 160+ world currencies
13. **How-to Guide** - In-app tutorial screen
14. **In-App Update** - Google Play in-app update prompts (Android-only); priority >= 4 forces immediate update, otherwise flexible background update

## Dependencies (Key)

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` + `riverpod_annotation` | State management |
| `isar_community` + `isar_community_flutter_libs` | Local NoSQL database |
| `shared_preferences` | Key-value storage |
| `fl_chart` | Charts (bar, line) |
| `google_sign_in` + `googleapis` + `extension_google_sign_in_as_googleapis_auth` | Google Drive backup |
| `share_plus` | Share/export files |
| `file_picker` | Import CSV |
| `google_fonts` | Typography |
| `intl` | Date formatting |
| `uuid` | Unique ID generation |
| `path_provider` | App directory paths |
| `in_app_update` | Google Play in-app update API (Android-only) |

## Build & Run

```bash
# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build APK
flutter build apk

# Regenerate Riverpod providers (NOT Isar)
dart run build_runner build --delete-conflicting-outputs
```

## Common Patterns

- **Dark mode check**: `Theme.of(context).brightness == Brightness.dark`
- **Currency loading**: Each screen loads currency from `CurrencyService.getSelectedCurrency()` in `initState`
- **Animation**: Most screens use `AnimationController` + staggered entrance animations
- **Vehicle icon resolution**: Repeated `_vehicleIconMap` const in multiple files mapping string keys to `Icons.*`
- **Error handling**: SnackBars with colored backgrounds (green=success, red=error)
- **Gradient theme**: Purple-blue gradient (`#667eea`, `#764ba2`, `#2196F3`) used in AddFuel, VehicleManagement, and History AppBar
- **In-app update**: `AppUpdateService.checkForUpdate(context)` called once via `addPostFrameCallback` in HomeScreen's `initState`; only runs on Android, silently skips on iOS

## Warnings

- Do NOT modify `fuel_entry.g.dart` manually — it's Isar-generated code
- Do NOT add `isar_generator` to dev_dependencies (analyzer conflicts)
- The `clearAllSharedPreferences()` in `FuelStorageService` actually clears Isar, not SharedPreferences (naming is misleading)
- Vehicle icon map (`_vehicleIconMap`) is duplicated across 4+ files — when adding new vehicle types, update all instances
