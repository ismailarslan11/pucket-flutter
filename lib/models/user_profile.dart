class UserProfile {
  final String uid;
  String name;
  int elo;
  int wins;
  int losses;
  int matches;
  String league;
  String? photoUrl;
  bool isAnonymous;

  UserProfile({
    required this.uid,
    required this.name,
    this.elo = 1000,
    this.wins = 0,
    this.losses = 0,
    this.matches = 0,
    this.league = 'Bronz',
    this.photoUrl,
    this.isAnonymous = false,
  });

  factory UserProfile.fromServer(Map<String, dynamic> json, {bool? isAnonymous}) {
    return UserProfile(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? 'Oyuncu',
      elo: (json['elo'] as num?)?.toInt() ?? 1000,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      matches: (json['matches'] as num?)?.toInt() ?? 0,
      league: json['league'] as String? ?? 'Bronz',
      isAnonymous: isAnonymous ?? json['isAnonymous'] as bool? ?? false,
    );
  }

  factory UserProfile.fromFirestore(Map<String, dynamic> json, String uid) {
    return UserProfile(
      uid: uid,
      name: json['username'] as String? ??
          json['displayName'] as String? ??
          'Oyuncu',
      elo: (json['elo'] as num?)?.toInt() ?? 1000,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      matches: (json['matches'] as num?)?.toInt() ?? 0,
      league: json['league'] as String? ?? 'Bronz',
      photoUrl: json['photoURL'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'elo': elo,
        'wins': wins,
        'losses': losses,
        'matches': matches,
        'league': league,
        if (photoUrl != null) 'photoURL': photoUrl,
        'isAnonymous': isAnonymous,
      };
}
