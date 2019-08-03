import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pebrapp_console/exceptions.dart';
import 'package:pebrapp_console/screens/user_screen.dart';
import 'package:pebrapp_console/user.dart';
import 'package:pebrapp_console/utils/switch_toolbox_utils.dart';

/// Main screen of the application. Shows a list of all PEBRApp users.
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  bool _isLoading = true;
  List<User> _pebraUsers;
  Map<User, bool> _selectedUsers = {};
  bool _selectMode = false;
  String _errorMessage = '';

  @override
  void initState() {
    getAllPEBRAppUsers().then((result) {
      setState(() {
        _pebraUsers = result;
        _isLoading = false;
      });
    })
    .catchError((e, s) {
      switch (e.runtimeType) {
        case SWITCHLoginFailedException:
          _errorMessage = 'Login to SWITCHtoolbox failed\n(wrong credentials?)';
          break;
        case SocketException:
          _errorMessage = 'Connection to SWITCHtoolbox failed\n(no internet connection?)';
          break;
        default:
          _errorMessage = 'An unknown error occurred:\n$e';
      }
      setState(() {
        _isLoading = false;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('PEBRApp Users'),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, textAlign: TextAlign.center))
              : buildUserList(context),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_selectMode) FloatingActionButton(
              onPressed: _selectAllUsers,
              tooltip: 'Select All',
              child: Icon(Icons.check),
            ),
            if (_selectMode) SizedBox(width: 10.0),
            if (_selectMode) FloatingActionButton(
              onPressed: _cancelSelection,
              tooltip: 'Cancel Selection',
              child: Icon(Icons.close),
            ),
            if (_selectMode) SizedBox(width: 10.0),
            FloatingActionButton(
              onPressed: _areUsersSelected ? _showSavePanel : null,
              tooltip: 'Download Selected',
              child: Icon(
                Icons.cloud_download,
                color: _areUsersSelected ? null : Colors.blueGrey,
              ),
              backgroundColor: _areUsersSelected ? null : Colors.grey,
            ),
          ],
        ),
      );
  }

  Widget buildUserList(BuildContext context) {
    return ListView(
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
            subtitle: Text('${pebraUser.firstname} ${pebraUser.lastname}'),
            title: Text(pebraUser.username),
            selected: _selectedUsers[pebraUser] ?? false,
            onTap: !_selectMode
              ? () {
                _pushUserScreen(pebraUser, context);
              }
              : () {
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
    );
  }

  void _pushUserScreen(User user, BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => UserScreen(user)));
  }

  void _selectAllUsers() {
    _pebraUsers.forEach((final user) {
      _selectedUsers[user] = true;
    });
    setState(() {});
  }

  void _cancelSelection() {
    setState(() {
      _selectedUsers = {};
      _selectMode = false;
    });
  }

  bool get _areUsersSelected {
    return _selectedUsers.values.any((final val) => val);
  }

  void _showSavePanel() {
    // TODO: ios/android impelementation
  }

}
