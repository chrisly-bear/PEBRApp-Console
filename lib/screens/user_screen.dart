import 'package:file_chooser/file_chooser.dart';
import 'package:flutter/material.dart';
import 'package:pebrapp_console/user.dart';
import 'package:pebrapp_console/utils/switch_toolbox_utils.dart';

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
  int get _numExcelFiles => widget._user.dataFiles.length;

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
            Text('Excel Documents: $_numExcelFiles', style: TextStyle(height: _lineHeight)),
            Text('Backup Documents: ${widget._user.backupFiles?.length}', style: TextStyle(height: _lineHeight)),
            Text('PIN Code Documents: ${widget._user.passwordFiles?.length}', style: TextStyle(height: _lineHeight)),
            SizedBox(height: 10.0),
            Align(
              alignment: Alignment.centerLeft,
              child: RaisedButton(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_downloadingExcel) SizedBox(child: CircularProgressIndicator(), height: 15.0, width: 15.0),
                    Text(
                      'Download Excel File${_numExcelFiles > 1 ? 's' : ''}',
                      style: TextStyle(color: _downloadingExcel ? Colors.transparent : null),
                    ),
                  ],
                ),
                onPressed: _numExcelFiles == 0 ? null : _downloadExcel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadExcel() {
    showSavePanel(suggestedFileName: 'PEBRApp-data-${widget._user.username}').then((result) {
      if (!result.canceled) {
        setState(() {
          _downloadingExcel = true;
        });
        downloadLatestExcelFiles([widget._user], result.paths.first).listen((progress) {
          print('excel download status: ${(progress*100).round()}%');
          if (progress >= 1.0) {
            Scaffold.of(_context).showSnackBar(SnackBar(content: Text('$_numExcelFiles Excel file${_numExcelFiles > 1 ? 's' : ''} downloaded')));
            setState(() {
              _downloadingExcel = false;
            });
          }
        }, onError: (error) {
          Scaffold.of(_context).showSnackBar(SnackBar(content: Text('An error occurred during the download 😢')));
          setState(() {
            _downloadingExcel = false;
          });
        });
      }
    });
  }

}
