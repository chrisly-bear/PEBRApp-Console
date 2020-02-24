import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:pebrapp_console/config/pebracloud_config.dart';
import 'package:pebrapp_console/exceptions.dart';
import 'package:pebrapp_console/user.dart';


/// Retrieves a list of all users which have a backup on PEBRAcloud.
///
/// Throws [PebraCloudAuthFailedException] if authentication with PEBRAcloud
/// fails.
///
/// Throws [HTTPStatusNotOKException] if interaction with PEBRAcloud fails.
Future<List<User>> getAllPEBRAppUsers() async {
  final uri = Uri.parse('$PEBRA_CLOUD_API/list-users');
  final resp = await http.get(uri, headers: {
    'token': PEBRA_CLOUD_TOKEN,
  });
  if (resp.statusCode == 401) {
    throw PebraCloudAuthFailedException();
  } else if (resp.statusCode != 200) {
    throw HTTPStatusNotOKException('An unexpected status code ${resp.statusCode} was returned while interacting with PEBRAcloud.\n');
  }
  final List<dynamic> json = jsonDecode(resp.body);
  final users = List<User>();
  for (Map<String, dynamic> u in json) {
    users.add(User(
      username: u['username'],
      firstname: u['firstname'],
      lastname: u['lastname'],
    ));
  }
  return users;
}


/// Downloads the most recent version of the excel file for the given [users].
///
/// @param [targetPath] Where to store the downloaded files. WARNING: Directory
/// will be erased if it already exists!
///
/// Throws [PebraCloudAuthFailedException] if authentication with PEBRAcloud
/// fails.
///
/// Throws [NoExcelFileException] if excel file was not found for one of the
/// given [users].
///
/// Throws [HTTPStatusNotOKException] if interaction with PEBRAcloud fails.
Stream<double> downloadLatestExcelFiles(List<User> users, String targetPath) async* {

  // start with 0%
  yield 0.0;

  final targetDir = Directory(targetPath);
  if (await targetDir.exists()) {
    await targetDir.delete(recursive: true);
  }
  await targetDir.create();

  final totalFiles = users.length;
  var currentFile = 1;
  for (final user in users) {
    final uri = Uri.parse('$PEBRA_CLOUD_API/download/$PEBRA_CLOUD_DATA_FOLDER/${user.username}');

    // download file
    final resp = await http.get(uri, headers: {
      'token': PEBRA_CLOUD_TOKEN,
    });

    if (resp.statusCode == 401) {
      throw PebraCloudAuthFailedException();
    } else if (resp.statusCode == 400) {
      throw NoExcelFileException(user.username);
    } else if (resp.statusCode != 200) {
      throw HTTPStatusNotOKException('An unexpected status code ${resp.statusCode} was returned while interacting with PEBRAcloud.\n');
    }

    // store file in target directory
    final fullPath = join(targetPath, '${currentFile}_${user.username}_${user.firstname}_${user.lastname}.xlsx');
    final excelFile = File(fullPath);
    await excelFile.writeAsBytes(resp.bodyBytes, flush: true);
    yield currentFile++ / totalFiles;
  }
}


/// Moves all files associated with the given [users] to their corresponding
/// archive folder on PEBRAcloud.
///
/// Throws [PebraCloudAuthFailedException] if authentication with PEBRAcloud
/// fails.
///
/// Throws [HTTPStatusNotOKException] if interaction with PEBRAcloud fails.
Stream<double> archiveUsers(List<User> users) async* {
  // start with 0%
  yield 0.0;
  final totalFiles = users.length;
  var currentFile = 1;
  for (final user in users) {
    final dataUri = Uri.parse('$PEBRA_CLOUD_API/archive/$PEBRA_CLOUD_DATA_FOLDER/${user.username}');
    final backupUri = Uri.parse('$PEBRA_CLOUD_API/archive/$PEBRA_CLOUD_BACKUP_FOLDER/${user.username}');
    final passwordUri = Uri.parse('$PEBRA_CLOUD_API/archive/$PEBRA_CLOUD_PASSWORD_FOLDER/${user.username}');
    final dataResp = await http.post(dataUri, headers: {'token': PEBRA_CLOUD_TOKEN});
    final backupResp = await http.post(backupUri, headers: {'token': PEBRA_CLOUD_TOKEN});
    final passwordResp = await http.post(passwordUri, headers: {'token': PEBRA_CLOUD_TOKEN});
    if (dataResp.statusCode == 401 || backupResp.statusCode == 401 || passwordResp.statusCode == 401) {
      throw PebraCloudAuthFailedException();
    } else if (dataResp.statusCode == 400 || backupResp.statusCode == 400 || passwordResp.statusCode == 400) {
      // ignore file not found error, if file does not exist there is nothing to archive
    } else if (dataResp.statusCode != 201 || backupResp.statusCode != 201 || passwordResp.statusCode != 201) {
      throw HTTPStatusNotOKException('An unexpected status code ${dataResp.statusCode} | ${backupResp.statusCode} | ${passwordResp.statusCode} was returned while interacting with PEBRAcloud.\n');
    }
    yield currentFile++ / totalFiles;
  }
}


/// Moves the password file associated with the given [users] to the password
/// archive folder on PEBRAcloud.
///
/// Throws [PebraCloudAuthFailedException] if authentication with PEBRAcloud
/// fails.
///
/// Throws [HTTPStatusNotOKException] if interaction with PEBRAcloud fails.
Stream<double> resetPIN(List<User> users) async* {
  // start with 0%
  yield 0.0;
  final totalFiles = users.length;
  var currentFile = 1;
  for (final user in users) {
    final passwordUri = Uri.parse('$PEBRA_CLOUD_API/archive/$PEBRA_CLOUD_PASSWORD_FOLDER/${user.username}');
    final passwordResp = await http.post(passwordUri, headers: {'token': PEBRA_CLOUD_TOKEN});
    if (passwordResp.statusCode == 401) {
      throw PebraCloudAuthFailedException();
    } else if (passwordResp.statusCode == 400) {
      // ignore file not found error, if file does not exist there is nothing to archive
    } else if (passwordResp.statusCode != 201) {
      throw HTTPStatusNotOKException('An unexpected status code ${passwordResp.statusCode} was returned while interacting with PEBRAcloud.\n');
    }
    yield currentFile++ / totalFiles;
  }
}
