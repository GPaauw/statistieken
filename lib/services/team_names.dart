// lib/services/team_names.dart
/// Centrale plek om teamnamen te configureren tijdens runtime.
class TeamNames {
  static String homeTeamName = "KV Flamingo's";
  static String awayTeamName = 'Tegenstanders';

  /// Wijzig één of beide teamnamen.
  static void setNames({String? home, String? away}) {
    if (home != null) homeTeamName = home;
    if (away != null) awayTeamName = away;
  }
}
