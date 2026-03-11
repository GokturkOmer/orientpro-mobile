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
import 'screens/scada/scada_dashboard_screen.dart';
import 'screens/scada/sensor_detail_screen.dart';
import 'screens/scada/alarm_list_screen.dart';
import 'screens/tour/tour_list_screen.dart';
import 'screens/digital_twin/digital_twin_screen.dart';
import 'screens/notifications/notification_screen.dart';
import 'screens/predictions/ai_prediction_screen.dart';
import 'screens/chatbot/chatbot_screen.dart';
import 'screens/tour/tour_detail_screen.dart';
import 'screens/tour/active_tour_screen.dart';
import 'screens/home/module_selection_screen.dart';
import 'screens/orientation/orientation_dashboard_screen.dart';
import 'screens/orientation/training_routes_screen.dart';
import 'screens/orientation/route_detail_screen.dart';
import 'screens/orientation/module_detail_screen.dart';
import 'screens/orientation/quiz_screen.dart';

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
        '/module-selection': (context) => const ModuleSelectionScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/orientation-dashboard': (context) => const OrientationDashboardScreen(),
        '/training-routes': (context) => const TrainingRoutesScreen(),
        '/route-detail': (context) => const RouteDetailScreen(),
        '/module-detail': (context) => const ModuleDetailScreen(),
        '/quiz': (context) => const QuizScreen(),
        '/equipment': (context) => const EquipmentListScreen(),
        '/work-orders': (context) => const WorkOrderListScreen(),
        '/inspections': (context) => const InspectionListScreen(),
        '/scada': (context) => const ScadaDashboardScreen(),
        '/alarms': (context) => const AlarmListScreen(),
        '/tours': (context) => const TourListScreen(),
        '/digital-twin': (context) => const DigitalTwinScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/chatbot': (context) => const ChatbotScreen(),
        '/ai-predictions': (context) => const AIPredictionScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/create-work-order') {
          final equipment = settings.arguments as Equipment;
          return MaterialPageRoute(builder: (_) => CreateWorkOrderScreen(equipment: equipment));
        }
        if (settings.name == '/tour-detail') {
          final routeId = settings.arguments as int;
          return MaterialPageRoute(builder: (_) => TourDetailScreen(routeId: routeId));
        }
        if (settings.name == '/active-tour') {
          final sessionId = settings.arguments as int;
          return MaterialPageRoute(builder: (_) => ActiveTourScreen(sessionId: sessionId));
        }
        if (settings.name == '/sensor-detail') {
          final sensorId = settings.arguments as int;
          return MaterialPageRoute(builder: (_) => SensorDetailScreen(sensorId: sensorId));
        }
        return null;
      },
    );
  }
}
