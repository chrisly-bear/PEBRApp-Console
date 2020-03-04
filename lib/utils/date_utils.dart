
/// Turns a date into a string denoting how much time has passed since
/// now and [date].
/// 
/// E.g. "just now", "2 hours ago", "1 minute ago".
String timeAgo(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inDays == 1) {
    return '${diff.inDays} day ago';
  } else if (diff.inDays > 1) {
    return '${diff.inDays} days ago';
  } else if (diff.inHours == 1) {
    return '${diff.inHours} hour ago';
  } else if (diff.inHours > 1) {
    return '${diff.inHours} hours ago';
  } else if (diff.inMinutes == 1) {
    return '${diff.inMinutes} minute ago';
  } else if (diff.inMinutes > 1) {
    return '${diff.inMinutes} minutes ago';
  } else {
    return 'just now';
  }
}
