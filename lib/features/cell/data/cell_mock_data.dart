class CellMockData {
  static const List<Map<String, String>> members = [
    {'name': 'prakashtwo', 'role': 'creator'},
    {'name': 'Kiduna Admin', 'role': 'member'},
  ];

  static const List<Map<String, dynamic>> activeGames = [
    {'code': 'ABCD', 'players': 2, 'maxPlayers': 4, 'host': 'prakashtwo'},
  ];

  static const List<Map<String, String>> gameHistory = [
    {'date': 'Aug 25, 2026', 'winner': 'prakashtwo', 'players': '4 players', 'duration': '12 min'},
    {'date': 'Aug 20, 2026', 'winner': 'Kiduna Admin', 'players': '4 players', 'duration': '8 min'},
    {'date': 'Aug 18, 2026', 'winner': 'prakashtwo', 'players': '3 players', 'duration': '15 min'},
  ];

  static const int maxMembers = 4;
  static const String cellName = 'Alpha Squad';
}
