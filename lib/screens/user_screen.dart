import 'dart:io';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pebrapp_console/user.dart';
import 'package:pebrapp_console/utils/pebracloud_utils.dart';

/// User screen which shows all user related information and actions.
class UserScreen extends StatefulWidget {
  /// Constructor
  const UserScreen(this._user);
  final User _user;
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {

  BuildContext _context;
  bool _downloadingExcel = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget._user.username),
      ),
      body: Builder(
        // create an inner BuildContext to be able to show SnackBars
        builder: (context) {
          _context = context;
          return _buildBody();
        }
      ),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget._user.username,
                  style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 5.0),
                Text(
                  '${widget._user.firstname} ${widget._user.lastname}',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400),
                ),
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: RaisedButton(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_downloadingExcel) SizedBox(child: CircularProgressIndicator(), height: 15.0, width: 15.0),
                    Text(
                      'Download Excel File',
                      style: TextStyle(color: _downloadingExcel ? Colors.transparent : null),
                    ),
                  ],
                ),
                onPressed: _downloadExcel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadExcel() async {
    setState(() {
      _downloadingExcel = true;
    });
    final tempDir = await getTemporaryDirectory();
    final targetDir = Directory(join(tempDir.path, 'PEBRApp-data'));
    downloadLatestExcelFiles([widget._user], targetDir.path).listen((progress) async {
      print('excel download status: ${(progress*100).round()}%');
      if (progress >= 1.0) {
        Scaffold.of(_context).showSnackBar(SnackBar(content: Text('Excel file downloaded')));
        setState(() {
          _downloadingExcel = false;
        });
        final filesInTargetDir = await targetDir.list(recursive: false, followLinks: false).where((entity) => entity is File).toList();
        if (filesInTargetDir.isEmpty) {
          Scaffold.of(_context).showSnackBar(SnackBar(content: Text('No Excel files found. 😞')));
        } else {
          final filesAsBytes = <String, List<int>>{};
          for (final File f in filesInTargetDir) {
            final filename = basename(f.path);
            final bytes = await f.readAsBytes();
            filesAsBytes[filename] = bytes;
          }
          await Share.files('PEBRApp Data', filesAsBytes, '*/*', text: 'PEBRApp Excel files downloaded from SWITCHtoolbox');
        }
      }
    }, onError: (error) {
      Scaffold.of(_context).showSnackBar(SnackBar(content: Text('An error occurred during the download 😢')));
      setState(() {
        _downloadingExcel = false;
      });
    });
  }

}
