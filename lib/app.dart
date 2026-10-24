import 'package:flutter/material.dart';

import 'pages/analyze_page.dart';
import 'theme/app_theme.dart';

/// Root aplikasi Steam Sentiment Analyzer (SESA).
class SesaApp extends StatelessWidget {
  const SesaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Steam Sentiment Analyzer',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AnalyzePage(),
    );
  }
}
