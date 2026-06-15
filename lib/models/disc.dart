class Disc {
  double vx;
  double vy;
  double vvx;
  double vvy;
  final int owner; // 0 = red, 1 = blue

  Disc({
    required this.vx,
    required this.vy,
    this.vvx = 0,
    this.vvy = 0,
    required this.owner,
  });

  Disc copyWith({
    double? vx,
    double? vy,
    double? vvx,
    double? vvy,
  }) {
    return Disc(
      vx: vx ?? this.vx,
      vy: vy ?? this.vy,
      vvx: vvx ?? this.vvx,
      vvy: vvy ?? this.vvy,
      owner: owner,
    );
  }
}
