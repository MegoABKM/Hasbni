import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hasbni/core/constants/api_constants.dart';
import 'package:hasbni/core/services/api_services.dart';
import 'package:http/http.dart' as http;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkServerHealth();
  }

  Future<void> _checkServerHealth() async {
    try {
      // 1. Try a quick ping to the server (e.g., 3 seconds)
      // We use a simple endpoint like login or just the base URL if possible
      // Using http directly to avoid ApiService logic for this specific check
      final uri = Uri.parse('${ApiConstants.baseUrl}/profiles'); 
      
      print("🔍 Checking server connection...");
      await http.get(uri).timeout(const Duration(seconds: 3));
      
      print("✅ Server is Online.");
      ApiService.isOfflineMode = false;

    } catch (e) {
      print("❌ Server unreachable ($e). switching to FAST OFFLINE MODE.");
      // 2. If it fails, force the app into Offline Mode
      ApiService.isOfflineMode = true;
    }

    // 3. Proceed to the app (The AuthCubit/AppNavigator will take over)
    // We don't need to navigate manually here because AppNavigator 
    // in main.dart is listening to AuthCubit. 
    // This check is purely to set the static flag.
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("جاري التحقق من الاتصال..."),
          ],
        ),
      ),
    );
  }
}