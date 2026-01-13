import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hasbni/core/theme/app_theme.dart';
import 'package:hasbni/presentation/cubits/auth/auth_cubit.dart';
import 'package:hasbni/presentation/cubits/auth/auth_state.dart';
import 'package:hasbni/presentation/cubits/inventory/inventory_cubit.dart'; // Import
import 'package:hasbni/presentation/cubits/profile/profile_cubit.dart';   // Import
import 'package:hasbni/presentation/cubits/session/session_cubit.dart';
import 'package:hasbni/presentation/cubits/session/session_state.dart';
import 'package:hasbni/presentation/screens/auth/login_screen.dart';
import 'package:hasbni/presentation/screens/home/employee_home_screen.dart';
import 'package:hasbni/presentation/screens/home/home_screen.dart';
import 'package:hasbni/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:hasbni/presentation/screens/roles/role_selection_screen.dart';
import 'package:hasbni/presentation/screens/splash_screen.dart';
import 'package:hasbni/core/services/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool? _hasSeenOnboarding;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  _hasSeenOnboarding = prefs.getBool('seen_onboarding') ?? false;

  await SoundService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit()..initialize()),
        BlocProvider(create: (context) => SessionCubit()),
        // --- GLOBAL PROVIDERS (ADDED) ---
        // Load Profile immediately so currency rates are ready
        BlocProvider(create: (context) => ProfileCubit()..loadProfile()),
        // Create InventoryCubit globally so HomeScreen can access it
        BlocProvider(create: (context) => InventoryCubit()), 
        // --------------------------------
      ],
      child: MaterialApp(
        title: 'Hasbni App',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar', '')],
        home: const AppNavigator(),
      ),
    );
  }
}
// --- THIS WIDGET CONTAINS THE FIX ---
class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    // We still use a listener to clear the session on sign-out.
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, authState) {
        if (authState.status == AuthStatus.unauthenticated) {
          context.read<SessionCubit>().clearSession();
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          switch (authState.status) {
            case AuthStatus.authenticated:
              final sessionCubit = context.read<SessionCubit>();

              // --- START OF THE FIX ---
              // If the user is authenticated but the session status is still 'initial',
              // it means we haven't tried to load the persisted role yet.
              // We trigger it here, inside the builder. This is safe because the
              // check prevents it from being called in a loop.
              if (sessionCubit.state.status == SessionStatus.initial) {
                sessionCubit.initializeSession();
              }
              // --- END OF THE FIX ---
                     
              // This inner builder now reacts to the SessionCubit's state changes.
              return BlocBuilder<SessionCubit, SessionState>(
                builder: (context, sessionState) {
                  // If the session role has been successfully determined...
                  if (sessionState.status == SessionStatus.determined) {
                    if (sessionState.role == SessionRole.manager) {
                      return const HomeScreen(); // Navigate to Manager home
                    } else if (sessionState.role == SessionRole.employee) {
                      return const EmployeeHomeScreen(); // Navigate to Employee home
                    }
                  }
                  // If the session needs a role to be selected...
                  if (sessionState.status == SessionStatus.needsSelection) {
                    return const RoleSelectionScreen(); // Show role selection
                  }
                  // Otherwise (status is initial or loading), show a splash screen.
                  // This is what the user sees during the brief moment
                  // initializeSession() is running.
                  return const SplashScreen();
                },
              );

            case AuthStatus.unauthenticated:
            case AuthStatus.failure:
              return const LoginScreen();

            case AuthStatus.loading:
            case AuthStatus.unknown:
            default:
              return const SplashScreen();
          }
        },
      ),
    );
  }
}
