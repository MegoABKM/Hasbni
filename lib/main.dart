import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hasbni/core/theme/app_theme.dart';
import 'package:hasbni/presentation/cubits/auth/auth_cubit.dart';
import 'package:hasbni/presentation/cubits/auth/auth_state.dart';
import 'package:hasbni/presentation/cubits/session/session_cubit.dart';
import 'package:hasbni/presentation/cubits/session/session_state.dart';
import 'package:hasbni/presentation/screens/auth/login_screen.dart';
import 'package:hasbni/presentation/screens/home/employee_home_screen.dart';
import 'package:hasbni/presentation/screens/home/home_screen.dart';
import 'package:hasbni/presentation/screens/roles/role_selection_screen.dart';
import 'package:hasbni/presentation/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:hasbni/core/services/sound_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    // استبدل هذه القيم بالقيم الخاصة بمشروعك
    url: 'https://ozqxjvureteaawvkelcl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im96cXhqdnVyZXRlYWF3dmtlbGNsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTExMjQ3NjgsImV4cCI6MjA2NjcwMDc2OH0.o0PIlWQo6AfGXR9ytQmCojKfJji_fw6mRtmQCoKtGzs',
  );

  await SoundService().initialize();
  print("Main: Sound service initialization attempted.");
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
