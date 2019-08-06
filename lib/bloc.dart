import 'dart:async';
import 'package:flutter/material.dart';

/// BLoC pattern to send state updates throughout the app.
class Bloc {
  Bloc._internal();

  /// Get the singleton Bloc instance.
  factory Bloc() {
    return _instance;
  }

  static final Bloc _instance = Bloc._internal();
  final _themeController = StreamController<ThemeData>();
  set theme(ThemeData newTheme) => _themeController.sink.add(newTheme);
  Stream<ThemeData> get themeStream => _themeController.stream;
}
