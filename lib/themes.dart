import 'package:flutter/material.dart';

/// Get light theme.
ThemeData get lightTheme => ThemeData.light().copyWith(
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'Roboto',
    )
);

/// Get dark theme.
ThemeData get darkTheme => ThemeData.dark().copyWith(
    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: 'Roboto',
    )
);

/// Get a map of the name of each available theme along with the theme itself.
Map<String, ThemeData> get allThemes => {
  'light': lightTheme,
  'dark': darkTheme,
};

/// Get the theme for the given [themeName]. Returns [lightTheme] if no matching
/// theme is found.
ThemeData themeWithName(String themeName) {
  if (allThemes.containsKey(themeName)) {
    return allThemes[themeName];
  }
  return lightTheme;
}