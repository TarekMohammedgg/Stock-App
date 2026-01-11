import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gdrive_tutorial/core/internet_connectino_helper.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';
import 'package:gdrive_tutorial/core/theme/toggle_theme.dart';
import 'package:gdrive_tutorial/core/widgets/lost_internet.dart';
import 'package:gdrive_tutorial/features/chatbot/presentation/views/chatbot_screen.dart';
import 'package:gdrive_tutorial/features/employee/presentation/view/employee_screen.dart';
import 'package:gdrive_tutorial/features/authentication/presentation/views/login_selection_screen.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/manager_screen.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/allProducts.dart';
import 'package:gdrive_tutorial/features/onboarding/presentation/views/onboarding_screen.dart';
import 'package:gdrive_tutorial/features/authentication/presentation/views/employee_login_screen.dart';
import 'package:gdrive_tutorial/features/authentication/presentation/views/manager_login_screen.dart';
import 'package:gdrive_tutorial/features/authentication/presentation/views/manager_signup_screen.dart';
import 'package:gdrive_tutorial/features/authentication/presentation/views/logout_screen.dart';
import 'package:gdrive_tutorial/features/insights/presentation/view/insight_screen.dart';
import 'package:gdrive_tutorial/features/calendar_view/presentation/view/calendar_view.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/manager_employee_dashboard.dart';
import 'package:gdrive_tutorial/features/search_products/presentation/view/search_items_screen.dart';
import 'package:gdrive_tutorial/features/employee/presentation/view/widgets/employee_attendance.dart';
import 'package:gdrive_tutorial/features/initialization/presentation/views/initialization_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize CacheHelper first - required for ThemeProvider
  await CacheHelper.init();

  // Initialize theme provider (uses CacheHelper internally)
  final themeProvider = ThemeProvider();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: ChangeNotifierProvider(
        create: (_) => themeProvider,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          builder: (context, child) {
            return Stack(
              children: [
                child!,
                StreamBuilder<bool>(
                  stream: NetworkService().internetStatusStream,
                  initialData: true,
                  builder: (context, snapshot) {
                    if (snapshot.data == false) {
                      return ConnectionErrorScreen();
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            );
          },
          home: const InitializationScreen(),
          routes: {
            ChatbotScreen.id: (context) => ChatbotScreen(),
            OnboardingScreen.id: (context) => const OnboardingScreen(),
            LoginSelectionScreen.id: (context) => const LoginSelectionScreen(),
            ManagerLoginScreen.id: (context) => const ManagerLoginScreen(),
            EmployeeLoginScreen.id: (context) => const EmployeeLoginScreen(),
            ManagerSignUpScreen.id: (context) => const ManagerSignUpScreen(),
            ManagerScreen.id: (context) => const ManagerScreen(),
            EmployeeScreen.id: (context) => const EmployeeScreen(),
            InsightsScreen.id: (context) => const InsightsScreen(),
            CalendarView.id: (context) => const CalendarView(),
            LogoutScreen.id: (context) => const LogoutScreen(),
            ManagerEmployeeDashboard.id: (context) =>
                const ManagerEmployeeDashboard(),
            SearchItemsScreen.id: (context) => const SearchItemsScreen(),
            EmployeeAttendance.id: (context) => const EmployeeAttendance(),
            AllProducts.id: (context) => const AllProducts(),
          },
        );
      },
    );
  }
}
