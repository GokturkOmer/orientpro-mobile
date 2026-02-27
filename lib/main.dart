import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'models/equipment.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/equipment/equipment_list_screen.dart';
import 'screens/work_orders/work_order_list_screen.dart';
import 'screens/work_orders/create_work_order_screen.dart';
import 'screens/inspections/inspection_list_screen.dart';

void main() {
  runApp(const ProviderScope(child: OrientProApp()));
}

class OrientProApp extends StatelessWidget {
  const OrientProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrientPro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/equipment': (context) => const EquipmentListScreen(),
        '/work-orders': (context) => const WorkOrderListScreen(),
        '/inspections': (context) => const InspectionListScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/create-work-order') {
          final equipment = settings.arguments as Equipment;
          return MaterialPageRoute(builder: (_) => CreateWorkOrderScreen(equipment: equipment));
        }
        return null;
      },
    );
  }
}
