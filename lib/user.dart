
import 'package:pebrapp_console/utils/date_utils.dart';

/// Represents a user of the PEBRApp.
class User {

  /// Constructor
  User({this.username, this.firstname, this.lastname, this.lastUpload});

  String username;
  String firstname;
  String lastname;
  DateTime lastUpload;

  String get lastUploadFormatted => timeAgo(lastUpload);

  @override
  bool operator ==(o) => o is User && o.username == username;

  @override
  int get hashCode => username.hashCode;
}
