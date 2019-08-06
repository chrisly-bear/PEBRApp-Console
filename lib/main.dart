import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:pebrapp_console/bloc.dart';
import 'package:pebrapp_console/screens/main_screen.dart';
import 'package:pebrapp_console/themes.dart' as t;

void main() {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  runApp(PEBRAppConsole());
}

/// MaterialApp for PEBRApp Console
class PEBRAppConsole extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object>(
      stream: Bloc().themeStream,
      initialData: t.lightTheme,
      builder: (context, snapshot) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PEBRApp Console',
          theme: snapshot.data,
          home: MainScreen(),
        );
      },
    );
  }
}
