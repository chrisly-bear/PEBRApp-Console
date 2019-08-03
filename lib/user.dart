import 'package:pebrapp_console/utils/switch_toolbox_utils.dart';

/// Represents a user of the PEBRApp.
class User {

  /// Constructor
  User({this.username, this.firstname, this.lastname, this.backupFiles, this.dataFiles, this.passwordFiles}) {
    backupFiles = [];
    dataFiles = [];
    passwordFiles = [];
  }

  String username;
  String firstname;
  String lastname;
  List<SwitchDoc> backupFiles;
  List<SwitchDoc> dataFiles;
  List<SwitchDoc> passwordFiles;

  @override
  bool operator ==(o) => o is User && o.username == username;

  @override
  int get hashCode => username.hashCode;
}
