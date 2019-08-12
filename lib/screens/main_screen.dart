import 'dart:io';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pebrapp_console/bloc.dart';
import 'package:pebrapp_console/exceptions.dart';
import 'package:pebrapp_console/screens/user_screen.dart';
import 'package:pebrapp_console/themes.dart' as t;
import 'package:pebrapp_console/user.dart';
import 'package:pebrapp_console/utils/switch_toolbox_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Main screen of the application. Shows a list of all PEBRApp users.
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  BuildContext _context;
  bool _isLoading = true;
  List<User> _pebraUsers;
  Map<User, bool> _selectedUsers = {};
  bool _selectMode = false;
  String _errorMessage = '';
  double _networkProgress = -1.0;

  List<User> get _selectedUsersList => _selectedUsers.entries.where((final map) => map.value).map((final map) => map.key).toList();
  bool get _hasError => _errorMessage.isNotEmpty;
  bool get _networkProcessing => _networkProgress >= 0.0;

  @override
  void initState() {
    SharedPreferences.getInstance().then((prefs) {
      final themeName = prefs.getString('theme');
      Bloc().theme = t.themeWithName(themeName);
    });
    _getUsersFromSwitch();
    super.initState();
  }

  void _getUsersFromSwitch() {
    setState(() {
      _isLoading = true;
      _selectedUsers = {};
      _selectMode = false;
    });
    getAllPEBRAppUsers().then((result) {
      setState(() {
        _pebraUsers = result;
        _errorMessage = '';
        _isLoading = false;
      });
    })
    .catchError((e, s) {
      _handleException(e);
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _handleException(e) {
    switch (e.runtimeType) {
      case SWITCHLoginFailedException:
        _errorMessage = 'Login to SWITCHtoolbox failed\n(wrong credentials?)';
        break;
      case SocketException:
        _errorMessage = 'Connection to SWITCHtoolbox failed\n(no internet connection?)';
        break;
      default:
        _errorMessage = 'An unknown error occurred:\n${e.toString().isEmpty ? e.runtimeType : e.toString()}';
        print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('PEBRApp Users${_areUsersSelected ? ' (${_selectedUsersList.length})' : ''}'),
          bottom: !_networkProcessing ? null : PreferredSize(child: LinearProgressIndicator(value: _networkProgress), preferredSize: Size(double.infinity, 10.0)),
          actions: (_hasError || _networkProcessing) ? [] : [
            if (!_selectMode) _popupMenu(),
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
          ],
        ),
        body: Builder(
          // create an inner BuildContext to be able to show SnackBars
          builder: (context) {
            _context = context;
            return _buildBody();
          },
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: (!_areUsersSelected || _networkProcessing || _hasError) ? [] : [
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
              tooltip: 'Download Latest Excel Files for Selected',
              child: Icon(Icons.file_download),
            ),
          ],
        ),
      );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_networkProcessing) {
      return Center(child: Text(
        'Processing…\n${(100*_networkProgress).toStringAsFixed(1)}%',
        textAlign: TextAlign.center,
        style: TextStyle(height: 1.5),
      ));
    }
    if (_hasError) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_errorMessage, textAlign: TextAlign.center),
          RaisedButton(child: Text('Reload'), onPressed: _getUsersFromSwitch),
        ],
      ));
    }
    return _buildUserList();
  }
  
  Widget _buildUserList() {
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
            ? () { _pushUserScreen(pebraUser); }
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

  void _pushUserScreen(User user) {
    Navigator.push(_context, MaterialPageRoute(builder: (context) => UserScreen(user)));
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

  void _deleteSelection() async {
    await showDialog(context: _context, builder: (context) {
      final selectedList = _selectedUsersList.map((u) {
        return Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: Row(
            children: [
              Icon(Icons.arrow_right),
              Text(u.username),
            ],
          ),
        );
      }).toList();
      const spacing = 10.0;
      return AlertDialog(
        title: Text('Warning!'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('This deletes all data associated with the selected users. This action cannot be undone!'),
              SizedBox(height: spacing),
              Text('Are you sure you want to delete the following users and all of their data?'),
              SizedBox(height: spacing),
              ...selectedList,
            ],
          ),
        ),
        actions: [
          FlatButton(child: Text('Cancel'), onPressed: () { Navigator.pop(_context); },),
          RaisedButton(
            child: Text('Delete (${_selectedUsersList.length})'),
            color: Theme.of(_context).buttonTheme.colorScheme.error,
            textColor: Theme.of(_context).buttonTheme.colorScheme.onError,
            onPressed: () {
              Navigator.pop(_context);
              deleteUsers(_selectedUsersList).listen((progress) {
                print('user deletion status: ${(progress*100).round()}%');
                setState(() {
                  _networkProgress = progress;
                });
                if (progress >= 1.0) {
                  Future.delayed(Duration(seconds: 1)).then((dynamic _) {
                    setState(() {
                      _networkProgress = -1.0; // tell the UI processing is done
                    });
                    _getUsersFromSwitch();
                  });
                }
              }, onError: (error) {
                setState(() {
                  _networkProgress = -1.0;
                  _handleException(error);
                });
              });
            },
          ),
        ],
      );
    });
  }

  void _archiveSelection() async {
    await showDialog(context: _context, builder: (context) {
      final selectedList = _selectedUsersList.map((u) {
        return Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: Row(
            children: [
              Icon(Icons.arrow_right),
              Text(u.username),
            ],
          ),
        );
      }).toList();
      const spacing = 10.0;
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('This moves all data associated with the selected users to the archives folder, which means the selected users will not be able to use their account anymore.'),
              SizedBox(height: spacing),
              Text('Are you sure you want to archive the following users?'),
              SizedBox(height: spacing),
              ...selectedList,
            ],
          ),
        ),
        actions: [
          FlatButton(child: Text('Cancel'), onPressed: () { Navigator.pop(_context); },),
          RaisedButton(
            child: Text('Archive (${_selectedUsersList.length})'),
            textColor: Theme.of(_context).buttonTheme.colorScheme.onPrimary,
            onPressed: () {
              Navigator.pop(_context);
              archiveUsers(_selectedUsersList).listen((progress) {
                print('user archiving status: ${(progress*100).round()}%');
                setState(() {
                  _networkProgress = progress;
                });
                if (progress >= 1.0) {
                  Future.delayed(Duration(seconds: 1)).then((dynamic _) {
                    setState(() {
                      _networkProgress = -1.0; // tell the UI processing is done
                    });
                    _getUsersFromSwitch();
                  });
                }
              }, onError: (error) {
                setState(() {
                  _networkProgress = -1.0;
                  _handleException(error);
                });
              });
            },
          ),
        ],
      );
    });
  }

  void _resetPinForSelection() async {
    await showDialog(context: _context, builder: (context) {
      final selectedList = _selectedUsersList.map((u) {
        return Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: Row(
            children: [
              Icon(Icons.arrow_right),
              Text(u.username),
            ],
          ),
        );
      }).toList();
      const spacing = 10.0;
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('The selected users will be prompted to enter a new PIN code the next time they log in to PEBRApp.'),
              SizedBox(height: spacing),
              Text('Are you sure you want to reset the PIN code for the following users?'),
              SizedBox(height: spacing),
              ...selectedList,
            ],
          ),
        ),
        actions: [
          FlatButton(child: Text('Cancel'), onPressed: () { Navigator.pop(_context); },),
          RaisedButton(
            child: Text('Reset PIN (${_selectedUsersList.length})'),
            textColor: Theme.of(_context).buttonTheme.colorScheme.onPrimary,
            onPressed: () {
              Navigator.pop(_context);
              resetPIN(_selectedUsersList).listen((progress) {
                print('user PIN resetting status: ${(progress*100).round()}%');
                setState(() {
                  _networkProgress = progress;
                });
                if (progress >= 1.0) {
                  Future.delayed(Duration(seconds: 1)).then((dynamic _) {
                    setState(() {
                      _networkProgress = -1.0; // tell the UI processing is done
                    });
                    _getUsersFromSwitch();
                  });
                }
              }, onError: (error) {
                setState(() {
                  _networkProgress = -1.0;
                  _handleException(error);
                });
              });
            },
          ),
        ],
      );
    });
  }

  void _downloadExcelForSelection() async {
    final tempDir = await getTemporaryDirectory();
    final targetDir = Directory(p.join(tempDir.path, 'PEBRApp-data'));
    downloadLatestExcelFiles(_selectedUsersList, targetDir.path).listen((progress) async {
      print('excel download status: ${(progress*100).round()}%');
      setState(() {
        _networkProgress = progress;
      });
      if (progress >= 1.0) {
        setState(() {
          _networkProgress = -1.0; // tell the UI processing is done
        });
        final filesInTargetDir = await targetDir.list(recursive: false, followLinks: false).where((entity) => entity is File).toList();
        if (filesInTargetDir.isEmpty) {
          Scaffold.of(_context).showSnackBar(SnackBar(content: Text('Something went wrong 🤭')));
        } else {
          final filesAsBytes = <String, List<int>>{};
          for (final File f in filesInTargetDir) {
            final filename = p.basename(f.path);
            final bytes = await f.readAsBytes();
            filesAsBytes[filename] = bytes;
          }
          await Share.files('PEBRApp Data', filesAsBytes, '*/*', text: 'PEBRApp Excel files downloaded from SWITCHtoolbox');
        }
      }
    }, onError: (error) {
      setState(() {
        _networkProgress = -1.0;
        _handleException(error);
      });
    });
  }

  Widget _popupMenu() {
    return PopupMenuButton<String>(
      onSelected: (selection) {
        switch (selection) {
          case 'Reload Data':
            _getUsersFromSwitch();
            break;
          case 'Select All':
            _selectAllUsers();
            break;
          case 'Change Theme':
            _showThemeDialog();
            break;
          default:
        }
      },
      itemBuilder: (context) {
        return ['Select All', 'Reload Data', 'Change Theme'].map((choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(choice),
          );
        }).toList();
      },
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: _context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: t.allThemes.map((themeName, themeData) {
              return MapEntry<String, MaterialButton>(
                themeName,
                FlatButton(
                  child: Text(themeName),
                  onPressed: () {
                    SharedPreferences.getInstance().then((prefs) {
                      prefs.setString('theme', themeName);
                    });
                    Bloc().theme = themeData;
                  },
                ),
              );
            }).values.toList(),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Close'),
              onPressed: () { Navigator.of(_context).pop(); },
            )
          ],
        );
      },
    );
  }

}
