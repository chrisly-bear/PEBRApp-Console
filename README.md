[![license](https://img.shields.io/github/license/chrisly-bear/PEBRApp-Console)](https://github.com/chrisly-bear/PEBRApp-Console/blob/desktop/LICENSE)

# PEBRApp Console

![logo](logo.png)

This is an administrative tool to help manage the PEBRApp users and data (see [PEBRApp repository](https://github.com/chrisly-bear/PEBRApp)). It is designed for desktop, but there's also a mobile variant on the `mobile` branch.

![screenshot](screenshot.png)

## Configure

The app accesses the data on [SWITCHtoolbox](https://toolbox.switch.ch). You need to set the proper values for the variables in `lib/config/switch_config.dart` for the app to work.

## Build and Run

The app is built with Flutter, Google's cross-platform UI toolkit. To build and run the app, you need to have the Flutter SDK installed (see https://flutter.dev/docs/get-started/install). At the time of writing, Flutter (1.13.0) supports building macOS desktop applications without further setup. Just make sure to **enable desktop support** (`flutter config --enable-macos-desktop`). Then you should see desktop (e.g. `macOS`) as a target platform (run `flutter devices` to check). 

To build for Windows or Linux the project relies on [Flutter Desktop Embedding](https://github.com/google/flutter-desktop-embedding) (FDE). This is currently untested and the FDE files might have to be updated with newer versions. See [flutter-desktop-embedding README](https://github.com/google/flutter-desktop-embedding/blob/master/README.md) and [Flutter Wiki](https://github.com/flutter/flutter/wiki/Desktop-shells) for more details.

Once you have desktop support ready, you can run the app with:

```bash
flutter run
```

If you want to specify a device to run the app on (check devices with `flutter devices`), use the `-d` argument:

```bash
# runs the app on desktop (macOS in this case)
flutter run -d macOS
```

### Troubleshooting

If you're getting a build error when running on macOS, try running `pod install` from the `macos/` directory.

Sometimes, newer versions of Flutter are incompatible with the desktop embedding project files, which can lead to build errors. In that case, you can try to check out a specific commit of Flutter which used to work (take a commit around the time when the desktop embedding files were last updated):

```bash
# go to your Flutter SDK directory
cd flutter
# the following commit should work
git checkout 500d7c50df4d794a92305d6ffe1ee10387faed43
# go to the PEBRApp Console project
cd PEBRApp-Console/
# build Flutter
flutter packages get
```

## Release

At the time of writing, Flutter supports release builds for macOS. To build a release version of the app run:

```bash
flutter build macos
```

You will then find the app in the `build/macos/Build/Products/Release/` directory.

## License

This project is licensed under the MIT license (see the [LICENSE](LICENSE) file for more information).

The app logo is exempt from this license and is **under copyright by Technify** (http://technifyls.com/).
