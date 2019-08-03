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
  final Map<String, bool> _selectedUsers = {};
  bool _selectMode = false;

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
      title: 'PEBRApp Console',
      // theme: ThemeData.dark(),
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
            : ListView(
                children: _pebraUsers.map((pebraUser) {
                  return Card(
                    elevation: 2.0,
                    clipBehavior: Clip.antiAlias,
                    margin: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                    child: ListTile(
                      leading: Icon(Icons.person),
                      trailing: !_selectMode ? null : Checkbox(
                        onChanged: (final value) {
                          setState(() {
                            _selectedUsers[pebraUser] = value;
                        });
                        },
                        value: _selectedUsers[pebraUser] ?? false,
                      ),
                      subtitle: Text(pebraUser),
                      title: Text('username'),
                      selected: _selectedUsers[pebraUser] ?? false,
                      onTap: !_selectMode ? null : () {
                        setState(() {
                          _selectedUsers[pebraUser] = !(_selectedUsers[pebraUser] ?? false);
                        });
                      },
                      onLongPress: _selectMode ? null : () {
                        setState(() {
                          _selectedUsers[pebraUser] = !(_selectedUsers[pebraUser] ?? false);
                          _selectMode = true;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _areUsersSelected ? _showSavePanel : null,
          tooltip: 'Download Selected',
          child: Icon(
            Icons.cloud_download,
            color: _areUsersSelected ? null : Colors.blueGrey,
          ),
          backgroundColor: _areUsersSelected ? null : Colors.grey,
        ),
      ),
    );
  }

  bool get _areUsersSelected {
    return _selectedUsers.values.any((final val) => val);
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
