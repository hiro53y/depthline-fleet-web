import 'package:flutter/material.dart';

import 'depthline_game_screen.dart';

class DepthlineFleetApp extends StatelessWidget {
  const DepthlineFleetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Depthline Fleet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3BB2D0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DepthlineGameScreen(),
    );
  }
}
