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
    
    url: 'https:
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


class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    
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

              
              
              
              
              
              if (sessionCubit.state.status == SessionStatus.initial) {
                sessionCubit.initializeSession();
              }
              

              
              return BlocBuilder<SessionCubit, SessionState>(
                builder: (context, sessionState) {
                  
                  if (sessionState.status == SessionStatus.determined) {
                    if (sessionState.role == SessionRole.manager) {
                      return const HomeScreen(); 
                    } else if (sessionState.role == SessionRole.employee) {
                      return const EmployeeHomeScreen(); 
                    }
                  }
                  
                  if (sessionState.status == SessionStatus.needsSelection) {
                    return const RoleSelectionScreen(); 
                  }
                  
                  
                  
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
