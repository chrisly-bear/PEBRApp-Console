import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
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

/// Uploads `sourceFile` to SWITCHtoolbox.
///
/// If `filename` is not provided the `sourceFile`'s file name will be used.
///
/// If `folderID` is not provided the file will be uploaded to the root folder (folderID = 1).
///
/// Throws `SWITCHLoginFailedException` if the login to SWITCHtoolbox fails.
///
/// Throws `SocketException` if there is no internet connection or SWITCH cannot be reached.
Future<void> uploadFileToSWITCHtoolbox(File sourceFile, {String filename, int folderID = 1}) async {

  // get necessary cookies
  final _shibsessionCookie = await _getShibSession(SWITCH_USERNAME, SWITCH_PASSWORD);
  final _mydmsSessionCookie = await _getMydmsSession(_shibsessionCookie);
  final _cookieHeaderString = '${_mydmsSessionCookie.split(' ').first} ${_shibsessionCookie.split(' ').first}';

  // upload file
  final _req1 = http.MultipartRequest('POST', Uri.parse('https://letodms.toolbox.switch.ch/$SWITCH_TOOLBOX_PROJECT/op/op.AddDocument.php'))
    ..headers['Cookie'] = _cookieHeaderString
    ..files.add(await http.MultipartFile.fromPath('userfile[]', sourceFile.path))
    ..fields.addAll({
      'name': filename == null ? '${sourceFile.path.split('/').last}' : filename,
      'folderid': '$folderID',
      'sequence': '1',
    });

  final _resp2Stream = await _req1.send();
  final _resp2 = await http.Response.fromStream(_resp2Stream);
  // TODO: return something to indicate whether the upload was successful or not
}

/// Downloads the excel file from SWITCHtoolbox for the given [username].
///
/// @param [targetPath] Where to store the downloaded file. Must be a complete path (including the filename).
///
/// Throws `DocumentNotFoundException` if no password file is available for the
/// given [username].
Future<File> downloadExcelFile(String username, String targetPath) async {

  // get necessary cookies
  final _shibsessionCookie = await _getShibSession(SWITCH_USERNAME, SWITCH_PASSWORD);
  final _mydmssessionCookie = await _getMydmsSession(_shibsessionCookie);

  final documentName = await _getFirstDocumentNameForDocumentStartingWith(username, SWITCH_TOOLBOX_DATA_FOLDER_ID, _shibsessionCookie, _mydmssessionCookie);
  final switchDocumentId = await _getFirstDocumentIdForDocumentWithName(documentName, SWITCH_TOOLBOX_PASSWORD_FOLDER_ID, _shibsessionCookie, _mydmssessionCookie);
  final latestVersion = await _getLatestVersionOfDocument(switchDocumentId, _shibsessionCookie, _mydmssessionCookie);
  final absoluteLink = 'https://letodms.toolbox.switch.ch/$SWITCH_TOOLBOX_PROJECT/op/op.Download.php?documentid=$switchDocumentId&version=$latestVersion';
  final downloadUri = Uri.parse(absoluteLink);

  // download file
  final resp = await http.get(downloadUri,
    headers: {'Cookie': '$_shibsessionCookie; $_mydmssessionCookie'},
  );

  // store file in database directory
  final excelFile = File(targetPath);
  return await excelFile.writeAsBytes(resp.bodyBytes, flush: true);
}

/// Downloads the latest backup file that matches the loginData from SWITCHtoolbox.
/// Returns null if no matching backup is found.
///
/// @param [targetPath] Where to store the downloaded file. Must be a complete path (including the filename).
///
/// Throws `DocumentNotFoundException` if no backup is available for the loginData.
Future<File> downloadLatestBackup(String username, String targetPath) async {
  
  // get necessary cookies
  final _shibsessionCookie = await _getShibSession(SWITCH_USERNAME, SWITCH_PASSWORD);
  final _mydmssessionCookie = await _getMydmsSession(_shibsessionCookie);

  final documentName = await _getFirstDocumentNameForDocumentStartingWith(username, SWITCH_TOOLBOX_BACKUP_FOLDER_ID, _shibsessionCookie, _mydmssessionCookie);
  final switchDocumentId = await _getFirstDocumentIdForDocumentWithName(documentName, SWITCH_TOOLBOX_BACKUP_FOLDER_ID, _shibsessionCookie, _mydmssessionCookie);
  final latestVersion = await _getLatestVersionOfDocument(switchDocumentId, _shibsessionCookie, _mydmssessionCookie);
  final absoluteLink = 'https://letodms.toolbox.switch.ch/$SWITCH_TOOLBOX_PROJECT/op/op.Download.php?documentid=$switchDocumentId&version=$latestVersion';
  final downloadUri = Uri.parse(absoluteLink);

  // download file
  final resp = await http.get(downloadUri,
    headers: {'Cookie': '$_shibsessionCookie; $_mydmssessionCookie'},
  );

  // store file in database directory
  final backupFile = File(targetPath);
  return await backupFile.writeAsBytes(resp.bodyBytes, flush: true);
}

/// Uploads a new version of the document with name `sourceFile` on SWITCHtoolbox.
/// Update only works if a document with the name `documentName` is already in the specified folder on SWITCHtoolbox.
///
/// If `folderID` is not provided the update will be attempted in the root folder (folderId = 1).
///
/// Throws `SWITCHLoginFailedException` if the login to SWITCHtoolbox fails.
/// 
/// Throws `DocumentNotFoundException` if no matching document was found.
Future<void> updateFileOnSWITCHtoolbox(File sourceFile, String documentName, {int folderId = 1}) async {
  final _shibsessionCookie = await _getShibSession(SWITCH_USERNAME, SWITCH_PASSWORD);
  final _mydmssessionCookie = await _getMydmsSession(_shibsessionCookie);
  final _cookieHeaderString = '${_mydmssessionCookie.split(' ').first} ${_shibsessionCookie.split(' ').first}';
  final docId = await _getFirstDocumentIdForDocumentWithName(documentName, folderId, _shibsessionCookie, _mydmssessionCookie);

  // upload file
  final _req1 = http.MultipartRequest('POST', Uri.parse('https://letodms.toolbox.switch.ch/$SWITCH_TOOLBOX_PROJECT/op/op.UpdateDocument.php'))
    ..headers['Cookie'] = _cookieHeaderString
    ..files.add(await http.MultipartFile.fromPath('userfile', sourceFile.path))
    ..fields.addAll({
      'documentid': '$docId',
//      'expires': 'false',
    });

  final _resp2Stream = await _req1.send();
  final _resp2 = await http.Response.fromStream(_resp2Stream);
  // TODO: return something to indicate whether the upload was successful or not
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

/// Finds the full name of the document that starts with [startsWith] in the folder [folderId].
/// If there are several documents with a matching start string, it will return the name of the first one.
///
/// Throws [DocumentNotFoundException] if no matching document was found.
Future<String> _getFirstDocumentNameForDocumentStartingWith(String startsWith, int folderId, String _shibsessionCookie, String _mydmssessionCookie) async {
  // get list of files
  final resp = await http.get(
    Uri.parse('https://letodms.toolbox.switch.ch/$SWITCH_TOOLBOX_PROJECT/out/out.ViewFolder.php?folderid=$folderId'),
    headers: {'Cookie': '$_shibsessionCookie; $_mydmssessionCookie'},
  );

  // parse html
  final _doc = parse(resp.body);
  final _tableBody = _doc.querySelector('table[class="folderView"] > tbody');
  if (_tableBody == null) {
    // no documents are in SWITCHtoolbox
    throw DocumentNotFoundException();
  }
  final aElements = _tableBody.getElementsByTagName('a');

  // find first matching document
  for (final a in aElements) {
    final linkText = a.text;
    if (linkText.startsWith(startsWith)) {
      return linkText;
    }
  }
  // no matching document found
  throw DocumentNotFoundException();
}

/// Finds the document id of a document that matches `documentName` in the folder `folderId`.
/// If there are several documents with a matching name, it will return the id of the first one.
///
/// Throws 'DocumentNotFoundException' if no matching document was found.
Future<int> _getFirstDocumentIdForDocumentWithName(String documentName, int folderId, String _shibsessionCookie, String _mydmssessionCookie) async {

  // get list of files
  final resp = await http.get(
    Uri.parse('https://letodms.toolbox.switch.ch/$SWITCH_TOOLBOX_PROJECT/out/out.ViewFolder.php?folderid=$folderId'),
    headers: {'Cookie': '$_shibsessionCookie; $_mydmssessionCookie'},
  );

  // parse html
  final _doc = parse(resp.body);
  final _tableBody = _doc.querySelector('table[class="folderView"] > tbody');
  if (_tableBody == null) {
    // no documents are in SWITCHtoolbox
    throw DocumentNotFoundException();
  }
  final aElements = _tableBody.getElementsByTagName('a');

  // find first matching document
  for (final a in aElements) {
    final linkText = a.text;
    if (linkText == documentName) {
      final relativeLink = a.attributes['href'];
      final relativeUri = Uri.parse(relativeLink);
      final switchDocumentId = relativeUri.queryParameters['documentid'];
      return int.parse(switchDocumentId);
    }
  }
  // no matching document found
  throw DocumentNotFoundException();
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

  String docName;
  int docId;
  int containingFolder;
  List<int> versions;

  @override
  bool operator ==(o) => o is SwitchDoc && o.docId == docId;

  @override
  int get hashCode => docId.hashCode;
}
