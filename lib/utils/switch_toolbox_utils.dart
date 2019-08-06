import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:path/path.dart';
import 'package:pebrapp_console/config/switch_config.dart';
import 'package:pebrapp_console/exceptions.dart';
import 'package:pebrapp_console/user.dart';


/// Retrieves a list of all users which have at least one file on SWITCHtoolbox.
Future<List<User>> getAllPEBRAppUsers() async {
  final _shibsessionCookie = await _getShibSession(SWITCH_USERNAME, SWITCH_PASSWORD);
  final _mydmsSessionCookie = await _getMydmsSession(_shibsessionCookie);
  final backupDocs = await _getAllDocumentsInFolder(SWITCH_TOOLBOX_BACKUP_FOLDER_ID, _shibsessionCookie, _mydmsSessionCookie);
  final dataDocs = await _getAllDocumentsInFolder(SWITCH_TOOLBOX_DATA_FOLDER_ID, _shibsessionCookie, _mydmsSessionCookie);
  final passwordDocs = await _getAllDocumentsInFolder(SWITCH_TOOLBOX_PASSWORD_FOLDER_ID, _shibsessionCookie, _mydmsSessionCookie);
  final users = <User>{};
  backupDocs.forEach((switchDoc) {
    // file name has format 'username_firstname_lastname'
    final username = switchDoc.docName.split('_')[0];
    final firstname = switchDoc.docName.split('_')[1];
    final lastname = switchDoc.docName.split('_')[2];
    final existingUser = users.lookup(User(username: username));
    if (existingUser != null) {
      existingUser.backupFiles.add(switchDoc);
    } else {
      users.add(User(
        username: username,
        firstname: firstname,
        lastname: lastname,
        backupFiles: [switchDoc],
      ));
    }
  });
  dataDocs.forEach((switchDoc) {
    // file name has format 'username_firstname_lastname'
    final username = switchDoc.docName.split('_')[0];
    final firstname = switchDoc.docName.split('_')[1];
    final lastname = switchDoc.docName.split('_')[2];
    final existingUser = users.lookup(User(username: username));
    if (existingUser != null) {
      existingUser.dataFiles.add(switchDoc);
    } else {
      users.add(User(
        username: username,
        firstname: firstname,
        lastname: lastname,
        dataFiles: [switchDoc],
      ));
    }
  });
  passwordDocs.forEach((switchDoc) {
    // file name has format 'username'
    final username = switchDoc.docName;
    final existingUser = users.lookup(User(username: username));
    if (existingUser != null) {
      existingUser.passwordFiles.add(switchDoc);
    } else {
      users.add(User(
        username: username,
        passwordFiles: [switchDoc],
      ));
    }
  });
  return users.toList();
}

/// Downloads the most recent version of the excel files from SWITCHtoolbox for
/// the given [users].
///
/// @param [targetPath] Where to store the downloaded files. WARNING: Directory
/// will be erased if it already exists!
Stream<double> downloadLatestExcelFiles(List<User> users, String targetPath) async* {

  // start with 0%
  yield 0.0;

  var totalFiles = 0;
  for (final u in users) {
    totalFiles += u.dataFiles.length;
  }

  if (totalFiles == 0) {
    // no files to download, yield 100% status
    yield 1.0;
  }

  // get necessary cookies
  final _shibsessionCookie = await _getShibSession(SWITCH_USERNAME, SWITCH_PASSWORD);
  final _mydmssessionCookie = await _getMydmsSession(_shibsessionCookie);

  final targetDir = Directory(targetPath);
  if (await targetDir.exists()) {
    await targetDir.delete(recursive: true);
  }
  await targetDir.create();

  var currentFile = 1;
  for (final user in users) {
    for (final excelSwitchDoc in user.dataFiles) {
      final latestVersion = await _getLatestVersionOfDocument(excelSwitchDoc.docId, _shibsessionCookie, _mydmssessionCookie);
      final absoluteLink = 'https://letodms.toolbox.switch.ch/$SWITCH_TOOLBOX_PROJECT/op/op.Download.php?documentid=${excelSwitchDoc.docId}&version=$latestVersion';
      final downloadUri = Uri.parse(absoluteLink);

      // download file
      final resp = await http.get(downloadUri, headers: {'Cookie': '$_shibsessionCookie; $_mydmssessionCookie'});
      final filename = resp.headers['content-disposition'].split('"')[1];

      // store file in target directory
      final fullPath = join(targetPath, '${currentFile}_${user.username}_v${latestVersion}_$filename');
      final excelFile = File(fullPath);
      await excelFile.writeAsBytes(resp.bodyBytes, flush: true);
      yield currentFile++ / totalFiles;
    }
  }
}

/// Moves all files associated with the given [users] to their corresponding
/// archive folder on SWITCHtoolbox.
Stream<double> archiveUsers(List<User> users) async* {

  // start with 0%
  yield 0.0;

  var totalFiles = 0;
  for (final u in users) {
    totalFiles += u.dataFiles.length;
    totalFiles += u.backupFiles.length;
    totalFiles += u.passwordFiles.length;
  }

  if (totalFiles == 0) {
    // no files to archive, yield 100% status
    yield 1.0;
  }

  // get necessary cookies
  final _shibsessionCookie = await _getShibSession(SWITCH_USERNAME, SWITCH_PASSWORD);
  final _mydmssessionCookie = await _getMydmsSession(_shibsessionCookie);

  var currentFile = 1;
  for (final user in users) {
    for (final excelSwitchDoc in user.dataFiles) {
      await _archiveDoc(excelSwitchDoc, SWITCH_TOOLBOX_ARCHIVE_DATA_FOLDER_ID, _shibsessionCookie, _mydmssessionCookie);
      yield currentFile++ / totalFiles;
    }
    for (final backupSwitchDoc in user.backupFiles) {
      await _archiveDoc(backupSwitchDoc, SWITCH_TOOLBOX_ARCHIVE_BACKUP_FOLDER_ID, _shibsessionCookie, _mydmssessionCookie);
      yield currentFile++ / totalFiles;
    }
    for (final passwordSwitchDoc in user.passwordFiles) {
      await _archiveDoc(passwordSwitchDoc, SWITCH_TOOLBOX_ARCHIVE_PASSWORD_FOLDER_ID, _shibsessionCookie, _mydmssessionCookie);
      yield currentFile++ / totalFiles;
    }
  }
}

/// Moves the password file associated with the given [users] to the password
/// archive folder on SWITCHtoolbox.
Stream<double> resetPIN(List<User> users) async* {

  // start with 0%
  yield 0.0;

  var totalFiles = 0;
  for (final u in users) {
    totalFiles += u.passwordFiles.length;
  }

  if (totalFiles == 0) {
    // no files to archive, yield 100% status
    yield 1.0;
  }

  // get necessary cookies
  final _shibsessionCookie = await _getShibSession(SWITCH_USERNAME, SWITCH_PASSWORD);
  final _mydmssessionCookie = await _getMydmsSession(_shibsessionCookie);

  var currentFile = 1;
  for (final user in users) {
    for (final passwordSwitchDoc in user.passwordFiles) {
      await _archiveDoc(passwordSwitchDoc, SWITCH_TOOLBOX_ARCHIVE_PASSWORD_FOLDER_ID, _shibsessionCookie, _mydmssessionCookie);
      yield currentFile++ / totalFiles;
    }
  }
}

/// Deletes all files associated with the given [users]. This action cannot be
/// undone!
Stream<double> deleteUsers(List<User> users) async* {

  // start with 0%
  yield 0.0;

  var totalFiles = 0;
  for (final u in users) {
    totalFiles += u.dataFiles.length;
    totalFiles += u.backupFiles.length;
    totalFiles += u.passwordFiles.length;
  }

  if (totalFiles == 0) {
    // no files to delete, yield 100% status
    yield 1.0;
  }

  // get necessary cookies
  final _shibsessionCookie = await _getShibSession(SWITCH_USERNAME, SWITCH_PASSWORD);
  final _mydmssessionCookie = await _getMydmsSession(_shibsessionCookie);

  var currentFile = 1;
  for (final user in users) {
    for (final excelSwitchDoc in user.dataFiles) {
      await _deleteDoc(excelSwitchDoc, _shibsessionCookie, _mydmssessionCookie);
      yield currentFile++ / totalFiles;
    }
    for (final backupSwitchDoc in user.backupFiles) {
      await _deleteDoc(backupSwitchDoc, _shibsessionCookie, _mydmssessionCookie);
      yield currentFile++ / totalFiles;
    }
    for (final passwordSwitchDoc in user.passwordFiles) {
      await _deleteDoc(passwordSwitchDoc, _shibsessionCookie, _mydmssessionCookie);
      yield currentFile++ / totalFiles;
    }
  }
}

/// Moves [doc] to folder with [archiveFolderId].
Future<void> _archiveDoc(SwitchDoc doc, int archiveFolderId, String _shibsessionCookie, String _mydmsSessionCookie) async {
  final _ = await http.get(
    Uri.parse('https://letodms.toolbox.switch.ch/$SWITCH_TOOLBOX_PROJECT/op/op.MoveDocument.php?documentid=${doc.docId}&targetidform1=$archiveFolderId'),
    headers: {'Cookie': '$_shibsessionCookie; $_mydmsSessionCookie'},
  );
}

Future<void> _deleteDoc(SwitchDoc doc, String _shibsessionCookie, String _mydmsSessionCookie) async {
  final _ = await http.post(
    Uri.parse('https://letodms.toolbox.switch.ch/$SWITCH_TOOLBOX_PROJECT/op/op.RemoveDocument.php'),
    headers: {'Cookie': '$_shibsessionCookie; $_mydmsSessionCookie'},
    body: {'documentid': '${doc.docId}'},
  );
}

Future<List<SwitchDoc>> _getAllDocumentsInFolder(int folderId, String _shibsessionCookie, String _mydmssessionCookie) async {

  // get list of files
  final resp = await http.get(
    Uri.parse('https://letodms.toolbox.switch.ch/$SWITCH_TOOLBOX_PROJECT/out/out.ViewFolder.php?folderid=$folderId'),
    headers: {'Cookie': '$_shibsessionCookie; $_mydmssessionCookie'},
  );

  final docs = <SwitchDoc>[];
  // parse html
  final _doc = parse(resp.body);
  final _tableBody = _doc.querySelector('table[class="folderView"] > tbody');
  if (_tableBody == null) {
    // no documents are in SWITCHtoolbox
    return docs;
  }
  final aElements = _tableBody.getElementsByTagName('a');

  for (final a in aElements) {
    if (a.text.isNotEmpty) {
      final relativeLink = a.attributes['href'];
      final relativeUri = Uri.parse(relativeLink);
      final switchDocumentId = relativeUri.queryParameters['documentid'];
      docs.add(SwitchDoc(
        docName: a.text,
        docId: int.parse(switchDocumentId),
        containingFolder: folderId,
      ));
    }
  }
  return docs;
}

/// Finds the latest version of the document with `documentId`.
///
/// Throws `DocumentNotFoundException` if document with `documentId` does not exist.
Future<int> _getLatestVersionOfDocument(int documentId, String _shibsessionCookie, String _mydmssessionCookie) async {
  // get list of files
  final resp = await http.get(
    Uri.parse('https://letodms.toolbox.switch.ch/$SWITCH_TOOLBOX_PROJECT/out/out.ViewDocument.php?documentid=$documentId&showtree=1'),
    headers: {'Cookie': '$_shibsessionCookie; $_mydmssessionCookie'},
  );

  // parse html
  final _doc = parse(resp.body);
  final _contentHeadings = _doc.querySelectorAll('div[class="contentHeading"]');
  if (_contentHeadings.isEmpty) {
    throw DocumentNotFoundException();
  }
  for (final el in _contentHeadings) {
    if (el.text == 'Current version') {
      final sibling = el.nextElementSibling;
      final versionEl = sibling.querySelectorAll('table[class="folderView"] > tbody > tr > td')[1];
      final version = versionEl.text;
      return int.parse(version);
    }
  }

  // we should never reach this point -> maybe throw an exception instead?
  return null;
}

Future<String> _getShibSession(String username, String password) async {

  /// debug helper method: print the response object to console
  void _printHTMLResponse(http.Response r, {printBody = true}) {
    print('Response status: ${r.statusCode}');
    print('Response isRedirect: ${r.isRedirect}');
    print('Response headers: ${r.headers}');
    print('Response body:\n${r.body}');
  }


  // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% - 1 - %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


  // link composed with
  // https://www.switch.ch/aai/guides/discovery/login-link-composer/
  final _req1 = http.Request('GET', Uri.parse('https://letodms.toolbox.switch.ch/Shibboleth.sso/Login?entityID=https%3A%2F%2Feduid.ch%2Fidp%2Fshibboleth&target=https%3A%2F%2Fletodms.toolbox.switch.ch%2Fpebrapp-data%2F'))
  ..followRedirects = false;
  final _resp1Stream = await _req1.send();
  final _resp1 = await http.Response.fromStream(_resp1Stream);

  final _redirectUrl1 = _resp1.headers['location'];


  // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% - 2 - %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  // get JSESSIONID cookie

  final _req2 = http.Request('GET', Uri.parse(_redirectUrl1))
    ..followRedirects = false;
  final _resp2Stream = await _req2.send();
  final _resp2 = await http.Response.fromStream(_resp2Stream);

  final _jsessionidCookie = _resp2.headers['set-cookie'];
  const _host = 'https://login.eduid.ch';
  final _redirectUrl2 = _host + _resp2.headers['location'];


  // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% - 3 - %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


  final _req3 = http.Request('GET', Uri.parse(_redirectUrl2))
    ..followRedirects = false
    ..headers['Cookie'] = _jsessionidCookie;
  final _resp3Stream = await _req3.send();
  final _resp3 = await http.Response.fromStream(_resp3Stream);


  // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% - 4 - %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  // get RelayState and SAMLResponse tokens

  final _resp4 = await http.post(
      _redirectUrl2,
      headers: {'Cookie': _jsessionidCookie},
      body: {
        'j_username': username,
        'j_password': password,
        '_eventId_proceed': '',
      });


  // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% - 5 - %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  // get _shibsession_ cookie

  if (_resp4.statusCode != 200) {
    throw SWITCHLoginFailedException();
  }

  final _doc = parse(_resp4.body);
  final _formEl = _doc.querySelector('form');
  final _relayStateEl = _doc.querySelector('input[name="RelayState"]');
  final _samlResponseEl = _doc.querySelector('input[name="SAMLResponse"]');
  final _formUrl = _formEl.attributes['action'];
  final _relayState = _relayStateEl.attributes['value'];
  final _samlResponse = _samlResponseEl.attributes['value'];

  final _resp5 = await http.post(_formUrl, body: {
    'RelayState': _relayState,
    'SAMLResponse': _samlResponse,
  });

  final _shibsessionCookie = _resp5.headers['set-cookie'];

  return _shibsessionCookie;
}

Future<String> _getMydmsSession(String shibsessionCookie) async {
  final req = http.Request('GET', Uri.parse('https://letodms.toolbox.switch.ch/$SWITCH_TOOLBOX_PROJECT/op/op.Login.php?referuri='))
    ..headers['Cookie'] = shibsessionCookie
    ..followRedirects = false;
  final resp = await req.send();
  final mydmssessionCookie = resp.headers['set-cookie'];
  return mydmssessionCookie;
}

/// Represents a document on SWITCHtoolbox.
class SwitchDoc {

  /// Constructor
  SwitchDoc({this.docName, this.docId, this.containingFolder, this.versions});

  /// The name as it appears in SWITCHtoolbox. This is derived from the a (html)
  /// element.
  String docName;
  /// SWITCHtoolbox identifier. Uniquely identifies documents on SWITCHtoolbox.
  int docId;
  /// SWITCHtoolbox folder ID in which this document is contained.
  int containingFolder;
  /// All versions that are available for this document.
  List<int> versions;

  @override
  bool operator ==(o) => o is SwitchDoc && o.docId == docId;

  @override
  int get hashCode => docId.hashCode;
}
