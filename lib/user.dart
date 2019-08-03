import 'package:pebrapp_console/utils/switch_toolbox_utils.dart';

/// Represents a user of the PEBRApp.
class User {

  /// Constructor
  User({this.username, this.firstname, this.lastname, List<SwitchDoc> backupFiles, List<SwitchDoc> dataFiles, List<SwitchDoc> passwordFiles}) {
    this.backupFiles = backupFiles ?? [];
    this.dataFiles = dataFiles ?? [];
    this.passwordFiles = passwordFiles ?? [];
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
