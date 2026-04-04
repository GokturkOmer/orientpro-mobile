import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/role_helper.dart';
import 'models/equipment.dart';
import 'models/micro_learning.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/select_organization_screen.dart';
import 'screens/auth/consent_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/register_screen.dart';
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
import 'screens/orientation/quiz_list_screen.dart';
import 'screens/orientation/progress_screen.dart';
import 'screens/orientation/ai_assistant_screen.dart';
import 'screens/orientation/team_progress_screen.dart';
import 'screens/orientation/library_screen.dart';
import 'screens/orientation/announcement_screen.dart';
import 'screens/orientation/digital_form_screen.dart';
import 'screens/orientation/profile_screen.dart';
import 'screens/orientation/shift_calendar_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/content_manager_screen.dart';
import 'screens/admin/route_editor_screen.dart';
import 'screens/admin/module_editor_screen.dart';
import 'screens/admin/quiz_builder_screen.dart';
import 'screens/admin/document_pool_screen.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/content_approval_screen.dart';
import 'screens/admin/analytics_screen.dart';
import 'screens/admin/sector_template_screen.dart';
import 'screens/admin/role_management_screen.dart';
import 'screens/admin/maintenance_screen.dart';
import 'screens/admin/help_screen.dart';
import 'screens/super_admin/super_admin_screen.dart';
import 'screens/orientation/certificate_screen.dart';
import 'screens/orientation/badges_screen.dart';
import 'screens/orientation/leaderboard_screen.dart';
import 'screens/orientation/today_screen.dart';
import 'screens/admin/micro_learning_assign_screen.dart';
import 'screens/admin/micro_learning_results_screen.dart';
import 'screens/admin/shift_schedule_screen.dart';
import 'screens/orientation/micro_quiz_result_screen.dart';
import 'screens/subscription/subscription_screen.dart';
import 'providers/theme_provider.dart';
import 'services/local_notification_service.dart';

void main() {
  // Flutter framework hatalari
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) return;
    debugPrint('[HATA] Flutter: ${details.exceptionAsString()}');
  };

  // Platform hatalari (async hatalar dahil)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[HATA] Platform: $error\n$stack');
    return true;
  };

  LocalNotificationService.initialize();
  runApp(const ProviderScope(child: OrientProApp()));
}

class OrientProApp extends ConsumerWidget {
  const OrientProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    return MaterialApp(
      title: 'OrientPro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeState.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/select-organization': (context) => const SelectOrganizationScreen(),
        '/consent': (context) => const ConsentScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/module-selection': (context) => const ModuleSelectionScreen(),
        '/dashboard': (context) => const _ProGuard(child: DashboardScreen()),
        '/orientation-dashboard': (context) => const OrientationDashboardScreen(),
        '/training-routes': (context) => const TrainingRoutesScreen(),
        '/route-detail': (context) => const RouteDetailScreen(),
        '/module-detail': (context) => const ModuleDetailScreen(),
        '/quiz': (context) => const QuizScreen(),
        '/quizzes': (context) => const QuizListScreen(),
        '/progress': (context) => const ProgressScreen(),
        '/ai-assistant': (context) => const AiAssistantScreen(),
        '/team-progress': (context) => const TeamProgressScreen(),
        '/library': (context) => const LibraryScreen(),
        '/announcements': (context) => const AnnouncementScreen(),
        '/forms': (context) => const DigitalFormScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
        '/shifts': (context) => const ShiftCalendarScreen(),
        '/equipment': (context) => const _ProGuard(child: EquipmentListScreen()),
        '/work-orders': (context) => const _ProGuard(child: WorkOrderListScreen()),
        '/inspections': (context) => const _ProGuard(child: InspectionListScreen()),
        '/scada': (context) => const _ProGuard(child: ScadaDashboardScreen()),
        '/alarms': (context) => const _ProGuard(child: AlarmListScreen()),
        '/tours': (context) => const _ProGuard(child: TourListScreen()),
        '/digital-twin': (context) => const _ProGuard(child: DigitalTwinScreen()),
        '/notifications': (context) => const NotificationScreen(),
        '/chatbot': (context) => const ChatbotScreen(),
        '/ai-predictions': (context) => const _ProGuard(child: AIPredictionScreen()),
        '/admin': (context) => const _AdminGuard(child: AdminDashboardScreen()),
        '/admin/content': (context) => const _ContentEditorGuard(child: ContentManagerScreen()),
        '/admin/documents': (context) => const _AdminGuard(child: DocumentPoolScreen()),
        '/admin/users': (context) => const _AdminGuard(child: UserManagementScreen()),
        '/admin/approvals': (context) => const _ContentEditorGuard(child: ContentApprovalScreen()),
        '/admin/analytics': (context) => const _AdminGuard(child: AnalyticsScreen()),
        '/admin/templates': (context) => const _AdminGuard(child: SectorTemplateScreen()),
        '/admin/roles': (context) => const _AdminGuard(child: RoleManagementScreen()),
        '/admin/maintenance': (context) => const _AdminGuard(child: MaintenanceScreen()),
        '/admin/help': (context) => const _AdminGuard(child: HelpScreen()),
        '/super-admin': (context) => const _SuperAdminGuard(child: SuperAdminScreen()),
        '/badges': (context) => const BadgesScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
        '/today': (context) => const TodayScreen(),
        '/admin/micro-learning': (context) => const _AdminGuard(child: MicroLearningAssignScreen()),
        '/admin/micro-learning-results': (context) => const _AdminGuard(child: MicroLearningResultsScreen()),
        '/admin/shift-schedules': (context) => const _AdminGuard(child: ShiftScheduleScreen()),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/micro-quiz-result') {
          final result = settings.arguments as MicroQuizResult;
          return MaterialPageRoute(builder: (_) => MicroQuizResultScreen(result: result));
        }
        if (settings.name == '/certificate') {
          return MaterialPageRoute(builder: (_) => const CertificateScreen(), settings: settings);
        }
        if (settings.name == '/verify-email') {
          final email = settings.arguments as String;
          return MaterialPageRoute(builder: (_) => EmailVerificationScreen(email: email));
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
        if (settings.name == '/admin/route-editor') {
          final routeId = settings.arguments as String?;
          return MaterialPageRoute(builder: (_) => _ContentEditorGuard(child: RouteEditorScreen(routeId: routeId)));
        }
        if (settings.name == '/admin/module-editor') {
          final args = settings.arguments as Map<String, String?>;
          return MaterialPageRoute(builder: (_) => _ContentEditorGuard(child: ModuleEditorScreen(routeId: args['routeId']!, moduleId: args['moduleId'])));
        }
        if (settings.name == '/admin/quiz-builder') {
          final args = settings.arguments as Map<String, String?>;
          return MaterialPageRoute(builder: (_) => _ContentEditorGuard(child: QuizBuilderScreen(moduleId: args['moduleId']!, quizId: args['quizId'])));
        }
        if (settings.name == '/create-work-order') {
          final equipment = settings.arguments as Equipment;
          return MaterialPageRoute(builder: (_) => _ProGuard(child: CreateWorkOrderScreen(equipment: equipment)));
        }
        return null;
      },
    );
  }
}

/// Pro modulu icin route guard (SCADA, ekipman, is emri vb.)
class _ProGuard extends ConsumerWidget {
  final Widget child;
  const _ProGuard({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (RoleHelper.canAccessPro(auth.user?.role)) return child;
    return const _AccessDeniedScreen();
  }
}

/// Admin paneli icin route guard
class _AdminGuard extends ConsumerWidget {
  final Widget child;
  const _AdminGuard({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (RoleHelper.isAdmin(auth.user?.role, permissions: auth.user?.permissions)) return child;
    return const _AccessDeniedScreen();
  }
}

/// Platform sahibi icin route guard — is_super_admin==true zorunlu
class _SuperAdminGuard extends ConsumerWidget {
  final Widget child;
  const _SuperAdminGuard({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.user?.isSuperAdmin == true) return child;
    return const _AccessDeniedScreen();
  }
}

/// Icerik yonetimi icin route guard (admin + mudur + sef)
class _ContentEditorGuard extends ConsumerWidget {
  final Widget child;
  const _ContentEditorGuard({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (RoleHelper.canEditContent(auth.user?.role, permissions: auth.user?.permissions)) return child;
    return const _AccessDeniedScreen();
  }
}

/// Yetkisiz erisim ekrani
class _AccessDeniedScreen extends StatelessWidget {
  const _AccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scada.bg,
      appBar: AppBar(
        backgroundColor: context.scada.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ScadaColors.cyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ScadaColors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock, size: 48, color: ScadaColors.red),
          ),
          const SizedBox(height: 20),
          Text('Erisim Yetkiniz Yok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.scada.textPrimary)),
          const SizedBox(height: 8),
          Text('Bu sayfaya erisim icin yetkiniz bulunmamaktadir.', style: TextStyle(fontSize: 13, color: context.scada.textSecondary)),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/module-selection'),
            icon: const Icon(Icons.home, size: 18),
            label: const Text('Ana Sayfaya Don'),
          ),
        ]),
      ),
    );
  }
}
