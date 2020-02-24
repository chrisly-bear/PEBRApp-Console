
/// Represents a user of the PEBRApp.
class User {

  /// Constructor
  User({this.username, this.firstname, this.lastname});

  String username;
  String firstname;
  String lastname;

  @override
  bool operator ==(o) => o is User && o.username == username;

  @override
  int get hashCode => username.hashCode;
}
