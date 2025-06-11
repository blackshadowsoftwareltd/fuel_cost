# 🚗 Fuel Cost Tracker

A beautiful and modern Flutter app for tracking fuel consumption, costs, and calculating mileage efficiency with real-time odometer tracking.

## ✨ Features

### 🏠 **Dashboard Overview**
- **Beautiful gradient interface** with modern Material 3 design
- **Smart statistics cards** showing:
  - Total money spent on fuel
  - Total liters consumed
  - Number of fuel entries
  - Average mileage or current odometer reading
- **Quick action buttons** for easy navigation

### ⛽ **Fuel Entry Management**
- **Intuitive form design** with enhanced input fields
- **Real-time mileage calculation** as you type
- **Smart odometer tracking** with validation
- **Live cost preview** showing total expense
- **Detailed calculation breakdown** with mathematical formulas

### 📊 **Mileage Calculation**
- **Automatic efficiency tracking** between fill-ups
- **Distance calculation** using odometer readings
- **km/L consumption display** with detailed breakdown
- **Historical average** across all entries
- **Mathematical formula visualization**

### ⚙️ **Data Management**
- **Elegant settings screen** with gradient design
- **Selective data clearing** options:
  - Clear fuel entries only
  - Clear odometer data only
  - Clear all fuel data
  - Complete app reset
- **Confirmation dialogs** with safety warnings
- **Beautiful success/error notifications**

### 📱 **Modern UI/UX**
- **Gradient backgrounds** throughout the app
- **Rounded corners** and soft shadows
- **Color-coded elements** for better organization
- **Smooth animations** and transitions
- **Responsive design** for all screen sizes
- **Material 3 design system** implementation

## 🎨 Screenshots

> **📱 To view screenshots:** Run the app and capture images, then replace the placeholders below with actual screenshot files.

### Main Dashboard
<!-- Replace with: ![Main Dashboard](screenshots/main_dashboard.png) -->
**🔄 Screenshot needed: Main screen with gradient background, stats cards, and action buttons**

*The main dashboard featuring colorful statistics cards and gradient action buttons*

### Add Fuel Entry  
<!-- Replace with: ![Add Fuel Entry](screenshots/add_fuel_screen.png) -->
**🔄 Screenshot needed: Add fuel form with enhanced input fields and real-time preview**

*Enhanced fuel entry form with real-time mileage calculation and cost preview*

### Mileage Calculation
<!-- Replace with: ![Mileage Calculation](screenshots/mileage_calculation.png) -->
**🔄 Screenshot needed: Detailed calculation breakdown showing mathematical formulas**

*Detailed mileage calculation with step-by-step mathematical breakdown*

### Settings & Data Management
<!-- Replace with: ![Settings Screen](screenshots/settings_screen.png) -->
**🔄 Screenshot needed: Settings screen with colorful management options**

*Beautiful settings screen with gradient cards for data management options*

---

### 📸 **How to Add Screenshots:**

1. **Run the app:** `flutter run`
2. **Navigate through screens** and take screenshots
3. **Save images** to `screenshots/` folder with these names:
   - `main_dashboard.png`
   - `add_fuel_screen.png` 
   - `mileage_calculation.png`
   - `settings_screen.png`
4. **Uncomment the image links** above and remove placeholder text

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Android device or emulator / iOS device or simulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/fuel_cost_tracker.git
   cd fuel_cost_tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2  # Local data storage
  cupertino_icons: ^1.0.2     # iOS-style icons

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0       # Code linting
```

## 🏗️ Architecture

### Project Structure
```
lib/
├── main.dart                 # App entry point and main screen
├── models/
│   └── fuel_entry.dart      # Fuel entry data model
├── screens/
│   ├── add_fuel_screen.dart # Fuel entry form
│   ├── fuel_history_screen.dart # Historical data view
│   └── settings_screen.dart # Data management
└── services/
    └── fuel_storage_service.dart # Data persistence layer
```

### Key Components

#### **FuelEntry Model**
- Stores fuel amount, price, cost, date, and odometer reading
- Includes static methods for mileage calculation
- JSON serialization for storage

#### **FuelStorageService**
- SharedPreferences-based data persistence
- Methods for CRUD operations
- Statistics calculation (totals, averages)
- Data clearing functionality

#### **Modern UI Components**
- Gradient-based stat cards
- Enhanced form fields with colored icons
- Real-time calculation displays
- Responsive action buttons

## 🎯 How to Use

### 1. **Adding Your First Fuel Entry**
- Tap "Add Fuel Entry" on the main screen
- Enter fuel amount and price per liter
- Optionally add your current odometer reading
- Watch the real-time cost and mileage calculation
- Tap "Save Fuel Entry" to store the data

### 2. **Tracking Mileage**
- Enter odometer readings for automatic mileage calculation
- The app calculates distance traveled between fill-ups
- View detailed mathematical breakdown of efficiency
- Monitor average mileage across all entries

### 3. **Managing Your Data**
- Access settings via the gear icon
- Choose specific data to clear:
  - **Fuel Entries**: Remove fill-up history, keep odometer
  - **Odometer Data**: Reset odometer, keep fuel history
  - **All Data**: Complete reset
- Confirm actions with safety dialogs

### 4. **Understanding Calculations**
The app calculates mileage using this formula:
```
Mileage (km/L) = Distance Traveled (km) ÷ Fuel Added (L)
Distance = Current Odometer - Previous Odometer
```

## 🔧 Customization

### Themes and Colors
The app uses a modern color palette:
- **Primary Blue**: `#2196F3` (buttons, accents)
- **Success Green**: `#4CAF50` (positive actions)
- **Warning Orange**: `#FF9800` (mileage, odometer)
- **Error Red**: `#E91E63` (costs, warnings)
- **Neutral Gray**: `#9E9E9E` (secondary actions)

### Modifying UI Elements
1. **Stat Cards**: Edit `_buildStatCard()` in `main.dart`
2. **Action Buttons**: Modify `_buildActionButton()` method
3. **Form Fields**: Update input decorations in `add_fuel_screen.dart`
4. **Colors**: Change gradient definitions throughout components

## 📊 Data Storage

### Local Storage
- Uses `SharedPreferences` for data persistence
- Stores data in JSON format for easy serialization
- Automatic data migration and validation

### Data Structure
```json
{
  "fuel_entries": [
    {
      "id": "timestamp",
      "liters": 40.0,
      "pricePerLiter": 1.50,
      "totalCost": 60.0,
      "dateTime": "2024-01-15T10:30:00Z",
      "odometerReading": 45250.0
    }
  ],
  "current_odometer": 45250.0
}
```

## 🛡️ Privacy & Security

- **Local-only storage**: All data stays on your device
- **No internet required**: Works completely offline
- **No data collection**: We don't collect any personal information
- **Secure storage**: Uses device's secure preference storage

## 🔄 Version History

### v1.0.0 (Current)
- ✅ Modern Material 3 UI design
- ✅ Real-time mileage calculation
- ✅ Odometer tracking with validation
- ✅ Comprehensive data management
- ✅ Beautiful gradient interfaces
- ✅ Mathematical calculation breakdown
- ✅ Responsive design for all devices

### Planned Features
- 📈 Charts and graphs for fuel trends
- 📤 Export data to CSV/Excel
- 🔔 Maintenance reminders
- 🌙 Dark mode support
- 📍 GPS-based fuel station finder

## 🤝 Contributing

We welcome contributions! Please feel free to submit pull requests or open issues.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

If you have any questions or need help:
- 📧 Email: support@fueltracker.com
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/fuel_cost_tracker/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/fuel_cost_tracker/discussions)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design team for the design system
- SharedPreferences plugin maintainers
- The open-source community

---

**Made with ❤️ and Flutter**

*Track your fuel, save your money, protect the environment* 🌱