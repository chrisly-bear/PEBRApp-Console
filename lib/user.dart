
import 'package:flutter/material.dart';
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

  Color get highlightColor {
    final now = DateTime.now();
    final diff = now.difference(lastUpload);
    if (diff.inDays >= 28) {
      return Colors.red;
    } else if (diff.inDays >= 14) {
      return Colors.orange;
    } else if (diff.inDays >= 7) {
      return Colors.yellow;
    }
    return null;
  }

  @override
  bool operator ==(o) => o is User && o.username == username;

  @override
  int get hashCode => username.hashCode;
}
