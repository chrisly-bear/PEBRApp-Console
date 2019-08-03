import 'dart:io';

import 'package:file_chooser/file_chooser.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:pebrapp_console/utils/SwitchToolboxUtils.dart';

void main() {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  runApp(PEBRAppConsole());
}

class PEBRAppConsole extends StatefulWidget {
  @override
  _PEBRAppConsoleState createState() => _PEBRAppConsoleState();
}

class _PEBRAppConsoleState extends State<PEBRAppConsole> {
  bool _isLoading = true;
  List<String> _pebraUsers;

  @override
  void initState() {
    getAllPEBRAppUsers().then((result) {
      setState(() {
        _pebraUsers = result;
        _isLoading = false;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // See https://github.com/flutter/flutter/wiki/Desktop-shells#fonts
        fontFamily: 'Roboto',
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('PEBRApp Console'),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: _pebraUsers.map((pebraUser) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 5.0, vertical: 5.0),
                    child: Container(
                      height: 50.0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 10.0),
                      child: Center(child: Text(pebraUser)),
                    ),
                  );
                }).toList(),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showSavePanel,
          tooltip: 'Download',
          child: Icon(Icons.cloud_download),
        ),
      ),
    );
  }

  void _showSavePanel() {
    showSavePanel((result, paths) {
      print(result);
      print(paths);
      if (result == FileChooserResult.ok) {
        for (final p in paths) {
          File(p).writeAsStringSync('file at "$p"');
        }
      }
    });
  }
}
