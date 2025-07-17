# Personal Manager

A comprehensive Flutter application for managing your personal life - combining expense tracking, task management, and productivity tools in one elegant app.

## ✨ Features

### 💰 Expense Management
- **Track Daily Expenses** - Record income and expenses with categories
- **Budget Planning** - Set monthly/weekly budgets and track spending
- **Expense Categories** - Organize spending by food, transport, entertainment, etc.
- **Visual Reports** - Charts and graphs to visualize spending patterns
- **Receipt Scanner** - Capture and store receipt images
- **Export Data** - Export expense reports to CSV/PDF

### ✅ Task Management
- **Create Tasks** - Add, edit, and delete tasks with due dates
- **Priority Levels** - Set task priorities (High, Medium, Low)
- **Task Categories** - Organize tasks by work, personal, shopping, etc.
- **Progress Tracking** - Mark tasks as complete/incomplete
- **Recurring Tasks** - Set up daily, weekly, monthly recurring tasks
- **Reminders** - Get notifications for upcoming tasks

### 📅 Calendar Integration
- **Calendar View** - View tasks and expenses in calendar format
- **Daily/Weekly/Monthly** - Multiple view options
- **Event Scheduling** - Schedule appointments and meetings
- **Deadline Tracking** - Never miss important deadlines

### 📊 Analytics & Reports
- **Spending Analytics** - Track spending trends over time
- **Task Completion** - Monitor productivity and task completion rates
- **Monthly Reports** - Comprehensive monthly summary
- **Goal Progress** - Track financial and productivity goals

### 🔧 Additional Features
- **Dark/Light Theme** - Choose your preferred theme
- **Data Backup** - Secure cloud backup of your data
- **Multi-Currency** - Support for multiple currencies
- **Offline Mode** - Work without internet connection
- **Data Export** - Export data to external applications

## 🛠️ Tech Stack

- **Framework:** Flutter
- **Language:** Dart
- **State Management:** Provider/Bloc
- **Database:** SQLite (local storage)
- **Charts:** FL Chart for data visualization
- **Notifications:** Flutter Local Notifications
- **Date Picker:** Flutter Date Picker
- **File Storage:** Path Provider
- **Architecture:** Clean Architecture (MVVM pattern)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio/VS Code
- iOS Simulator/Android Emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Nahianether/personal_manager.git
   cd personal_manager
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 🎯 How to Use

### Expense Tracking
1. **Add Expense**: Tap the "+" button → Select "Expense" → Enter amount and category
2. **View Reports**: Go to "Reports" tab → Select time period → View charts
3. **Set Budget**: Go to "Budget" → Set monthly limits for categories
4. **Add Income**: Record your income sources for better budget tracking

### Task Management
1. **Create Task**: Tap "+" → Select "Task" → Enter title, due date, and priority
2. **Mark Complete**: Tap the checkbox next to completed tasks
3. **Edit Task**: Long press on any task to edit or delete
4. **Set Reminders**: Enable notifications for important tasks

### Calendar View
1. **Switch Views**: Toggle between daily, weekly, and monthly views
2. **Add Events**: Tap any date to add tasks or expenses
3. **View Details**: Tap on any item to see full details

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── expense_model.dart    # Expense data structure
│   ├── task_model.dart       # Task data structure
│   └── user_model.dart       # User preferences
├── screens/                  # UI screens
│   ├── home_screen.dart      # Main dashboard
│   ├── expense/              # Expense management screens
│   │   ├── add_expense.dart
│   │   ├── expense_list.dart
│   │   └── expense_reports.dart
│   ├── tasks/                # Task management screens
│   │   ├── add_task.dart
│   │   ├── task_list.dart
│   │   └── task_calendar.dart
│   └── settings/             # App settings
│       ├── settings_screen.dart
│       └── backup_screen.dart
├── widgets/                  # Reusable UI components
│   ├── expense_card.dart     # Expense item display
│   ├── task_card.dart        # Task item display
│   ├── chart_widget.dart     # Chart components
│   └── date_picker.dart      # Date selection widget
├── services/                 # Business logic
│   ├── database_service.dart # SQLite operations
│   ├── notification_service.dart # Push notifications
│   └── backup_service.dart   # Data backup/restore
├── providers/                # State management
│   ├── expense_provider.dart # Expense state
│   ├── task_provider.dart    # Task state
│   └── theme_provider.dart   # Theme management
├── utils/                    # Utility functions
│   ├── constants.dart        # App constants
│   ├── helpers.dart          # Helper functions
│   └── themes.dart           # Theme configurations
└── database/                 # Database schema
    ├── database_helper.dart  # Database setup
    └── tables.dart           # Table definitions
```

## 🎨 Key Components

### Expense Model
```dart
class Expense {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final String? receiptPath;
  
  // Constructor and methods
}
```

### Task Model
```dart
class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate;
  final Priority priority;
  final bool isCompleted;
  final String category;
  
  // Constructor and methods
}
```

### Database Schema
- **Expenses Table**: id, title, amount, category, date, notes, receipt_path
- **Tasks Table**: id, title, description, due_date, priority, is_completed, category
- **Categories Table**: id, name, type (expense/task), color
- **Settings Table**: id, key, value

## 🔧 Configuration

### Adding New Categories
1. Navigate to Settings → Manage Categories
2. Add new expense or task categories
3. Assign colors and icons to categories

### Backup Settings
1. Go to Settings → Backup & Restore
2. Enable automatic backups
3. Set backup frequency (daily/weekly)

### Notification Settings
1. Settings → Notifications
2. Enable task reminders
3. Set reminder times and frequency

## 📊 Analytics Features

### Expense Analytics
- **Monthly Spending**: Track spending by month
- **Category Breakdown**: See which categories consume most budget
- **Trend Analysis**: Identify spending patterns
- **Budget vs Actual**: Compare budgeted vs actual spending

### Task Analytics
- **Completion Rate**: Track task completion percentage
- **Productivity Trends**: See your most productive times
- **Category Performance**: Which task categories you complete most
- **Overdue Analysis**: Identify frequently overdue task types

## 🔮 Future Enhancements

- **Cloud Synchronization** - Sync data across multiple devices
- **AI Insights** - Smart spending and productivity recommendations
- **Social Features** - Share goals and achievements
- **Integration** - Connect with banking apps and calendar services
- **Voice Commands** - Add tasks and expenses using voice
- **Widgets** - Home screen widgets for quick access

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🐛 Bug Reports

If you encounter any issues:

1. Check existing issues on GitHub
2. Create a new issue with detailed description
3. Include steps to reproduce the bug
4. Provide device and OS information
5. Attach screenshots if applicable

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Nahian Ether**
- **Company:** AKIJ iBOS Limited
- **Location:** Dhaka, Bangladesh
- **GitHub:** [@Nahianether](https://github.com/Nahianether)
- **Portfolio:** [portfolio.int8bit.xyz](https://portfolio.int8bit.xyz/)
- **LinkedIn:** [nahinxp21](https://www.linkedin.com/in/nahinxp21/)

## 🙏 Acknowledgments

- Built with Flutter framework by Google
- Icons from Flutter's Material Design
- Charts powered by FL Chart package
- Local notifications by Flutter Local Notifications
- Thanks to the Flutter community for amazing packages

---

*Take control of your personal life with this all-in-one management app. Track expenses, manage tasks, and boost your productivity - all in one beautiful Flutter application!*
