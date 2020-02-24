
class PebraCloudAuthFailedException implements Exception {}

class HTTPStatusNotOKException implements Exception {
  final message;

  HTTPStatusNotOKException([this.message]);

  String toString() {
    if (message == null) return "HTTPStatusNotOKException";
    return message;
  }
}

class NoExcelFileException implements Exception {
  final username;

  NoExcelFileException([this.username]);

  String toString() {
    if (username == null) return "NoExcelFileException";
    return "NoExcelFileException: No Excel file found for user '$username'";
  }
}
