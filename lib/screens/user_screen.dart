import 'package:flutter/material.dart';

/// User screen which shows all user related information and actions.
class UserScreen extends StatefulWidget {
  /// Constructor
  const UserScreen(this._user);
  final String _user;
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget._user),
      ),
      body: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RaisedButton(
              onPressed: () {},
              child: Text('Reset PIN Code'),
            ),
            RaisedButton(
              onPressed: () {},
              child: Text('Archive User'),
            ),
          ],
        ),
      ),
    );
  }
}
