import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'data/models/user_profile.dart';
import 'data/models/task.dart';
import 'data/models/scheduled_task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(ProductivityPeakAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(PriorityAdapter());
  Hive.registerAdapter(ScheduledTaskAdapter());

  await Hive.openBox<UserProfile>('userProfile');
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<ScheduledTask>('scheduledTasks');
  await Hive.openBox('settings');

  await initializeDateFormatting('en_US', null);

  runApp(
    const ProviderScope(
      child: ChronoApp(),
    ),
  );
}
