import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_chooser/file_chooser.dart';
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
    _getUsersFromSwitch();
    super.initState();
  }

  void _getUsersFromSwitch() {
    setState(() {
      _isLoading = true;
    });
    getAllPEBRAppUsers().then((result) {
      setState(() {
        _pebraUsers = result;
        _errorMessage = '';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('PEBRApp Users'),
          actions: [
              if (!_selectMode) IconButton(
                  tooltip: 'Select All Users',
                  icon: Icon(Icons.check_box),
                  onPressed: _selectAllUsers,
                ),
            if (_selectMode) _areUsersSelected
                ? IconButton(
                  tooltip: 'Deselect All Users',
                  icon: Icon(Icons.check_box_outline_blank),
                  onPressed: _deselectAllUsers,
                )
                : IconButton(
                  tooltip: 'Select All Users',
                  icon: Icon(Icons.check_box),
                  onPressed: _selectAllUsers,
                ),
            if (_selectMode) IconButton(
                  tooltip: 'Stop Selecting',
                  icon: Icon(Icons.close),
                  onPressed: _exitSelectMode,
                ),
            // _popupMenu(),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage.isEmpty
              ? buildUserList(context)
              : Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage, textAlign: TextAlign.center),
                  RaisedButton(child: Text('Reload'), onPressed: _getUsersFromSwitch),
                ],
              )),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: !_areUsersSelected ? [] : [
            FloatingActionButton(
              onPressed: _deleteSelection,
              tooltip: 'Delete Selected',
              child: Icon(Icons.delete),
            ),
            SizedBox(width: 10.0),
            FloatingActionButton(
              onPressed: _archiveSelection,
              tooltip: 'Archive Selected',
              child: Icon(Icons.archive),
            ),
            SizedBox(width: 10.0),
            FloatingActionButton(
              onPressed: _resetPinForSelection,
              tooltip: 'Reset PIN Code for Selected',
              child: Icon(Icons.lock),
            ),
            SizedBox(width: 10.0),
            FloatingActionButton(
              onPressed: _downloadExcelForSelection,
              tooltip: 'Download Excel Files for Selected',
              child: Icon(Icons.file_download),
            ),
          ],
        ),
      );
  }

  Widget buildUserList(BuildContext context) {
    final _userCards = _pebraUsers.map((pebraUser) {
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
    }).toList();
    return ListView(
      physics: BouncingScrollPhysics(),
      children: [
        ..._userCards,
        SizedBox(height: 8.0),
      ],
    );
  }

  void _pushUserScreen(User user, BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => UserScreen(user)));
  }

  void _selectAllUsers() {
    _selectMode = true;
    _pebraUsers.forEach((final user) {
      _selectedUsers[user] = true;
    });
    setState(() {});
  }

  void _deselectAllUsers() {
    setState(() {
      _selectedUsers = {};
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selectedUsers = {};
      _selectMode = false;
    });
  }

  bool get _areUsersSelected {
    return _selectedUsers.values.any((final val) => val);
  }

  void _deleteSelection() {
    // TODO: implement
  }

  void _archiveSelection() {
    // TODO: implement
  }

  void _resetPinForSelection() {
    // TODO: implement
  }

  void _downloadExcelForSelection() {
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

  Widget _popupMenu() {
    return PopupMenuButton<String>(
      onSelected: (selection) {
        switch (selection) {
          case 'Cancel Selection':
            _exitSelectMode();
            break;
          case 'Select All':
            _selectAllUsers();
            break;
          default:
        }
      },
      itemBuilder: (context) {
        return ['Cancel Selection', 'Select All'].map((choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(choice),
          );
        }).toList();
      },
    );
  }

}
