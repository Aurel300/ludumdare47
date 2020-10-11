class Hacks {
  public static final AO:Float = Math.PI / 4;
  public static final AQ:Float = Math.PI / 2;
  public static final AH:Float = Math.PI;
  public static final AF:Float = Math.PI * 2;

  public static inline function clipAngle(a:Float):Float {
    return (a < -AH ? a + AF : (a > AH ? a - AF : a));
  }

  public static function clamp(a:Float, min:Float, max:Float):Float {
    return (a < min ? min : (a > max ? max : a));
  }

  public static function quadInOut(x:Float):Float {
    return (x < .5
      ? 2 * x * x
      : -.5 * (x = 2 * x - 2) * x + 1);
  }
}
