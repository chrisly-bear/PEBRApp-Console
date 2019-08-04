import 'package:flutter/material.dart';
import 'package:pebrapp_console/user.dart';

/// User screen which shows all user related information and actions.
class UserScreen extends StatefulWidget {
  /// Constructor
  const UserScreen(this._user);
  final User _user;
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget._user.username),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    const _lineHeight = 1.5;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget._user.username,
              style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 5.0),
            Text(
              '${widget._user.firstname} ${widget._user.lastname}',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400),
            ),
            SizedBox(height: 10.0),
            Text('Excel Documents: ${widget._user.dataFiles?.length}', style: TextStyle(height: _lineHeight)),
            Text('Backup Documents: ${widget._user.backupFiles?.length}', style: TextStyle(height: _lineHeight)),
            Text('PIN Code Documents: ${widget._user.passwordFiles?.length}', style: TextStyle(height: _lineHeight)),
          ],
        ),
      ),
    );
  }

}
