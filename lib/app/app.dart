import 'package:flutter/material.dart';

import '../features/onboarding/presentation/onboarding_flow_page.dart';

class ECommerceApp extends StatelessWidget {
  const ECommerceApp({super.key});

  @override
  Widget build(BuildContext context) {
    const baseBg = Color(0xFFF5ECE7);
    const textPrimary = Color(0xFF3F2413);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'e-Mall',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: baseBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF26D21),
          primary: const Color(0xFFF26D21),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF6A4A35)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF7D5D47)),
        ),
      ),
      home: const OnboardingFlowPage(),
    );
  }
}
