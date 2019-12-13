import 'package:flutter/material.dart';

const Color _pebraPurple = Color(0xff004768);
const Color _pebraPurpleDark = Color(0xff002f45);
const Color _pebraPurpleDarker = Color(0xff001c29);
const Color _pebraRed = Color(0xfff97263);

/// Get light theme.
ThemeData get lightTheme => ThemeData(
    fontFamily: 'Roboto',
    primaryColor: _pebraPurple,
    // spinner & highlights
    accentColor: _pebraPurple,
    // floating action button
    floatingActionButtonTheme: ThemeData.light().floatingActionButtonTheme.copyWith(
      backgroundColor: _pebraRed,
    ),
    // active checkboxes
    toggleableActiveColor: _pebraPurple,
    // dialog close button
    buttonTheme: ThemeData.light().buttonTheme.copyWith(
      colorScheme: ColorScheme.light().copyWith(
        primary: _pebraPurple,
      )
    ),
);

/// Get purple theme.
ThemeData get purpleTheme => ThemeData(
  fontFamily: 'Roboto',
  // header
  primaryColor: _pebraPurpleDarker,
  // brightness
  brightness: Brightness.dark,
  // background of main screen
  scaffoldBackgroundColor: _pebraPurpleDark,
  // dialog background
  dialogBackgroundColor: _pebraPurple,
  // cards
  cardColor: _pebraPurple,
  // spinner & highlights
  accentColor: _pebraRed,
  // active checkboxes
  toggleableActiveColor: _pebraRed,
  // button
  buttonColor: _pebraRed,
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
  'purple': purpleTheme,
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
