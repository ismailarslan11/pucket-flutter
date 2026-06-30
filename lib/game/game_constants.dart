class GameConstants {
  static const double vw = 400;
  static const double vh = 700;
  static const double vHalf = vh / 2;
  static const double gapW = 72;
  static const double gapX = (vw - gapW) / 2;
  static const double wallHalfH = 8;
  static const double gapY = vHalf - wallHalfH;
  static const double gapH = wallHalfH * 2;
  static const double wallTop = vHalf - wallHalfH;
  static const double wallBottom = vHalf + wallHalfH;
  static const double discRadius = 22;

  static const double friction = 0.983;
  static const double restitution = 0.68;
  static const double slingMax = 88;
  static const double slingPower = 0.21;
}
