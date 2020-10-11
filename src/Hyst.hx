class Hyst {
  public var value:Float;
  public var target:Float;
  public var weight:Float;

  public function new(value:Float, ?tg:Float, ?weight:Float = .89) {
    this.value = value;
    if (tg == null) tg = value;
    this.target = tg;
    this.weight = weight;
  }

  public function tick():Float {
    return value = value * weight + target * (1 - weight);
  }

  public function tickI():Int {
    return Std.int(tick());
  }

  public function tickAngle():Float {
    value = value.clipAngle();
    target = target.clipAngle();
    var distAngle1 = Math.abs(target - value);
    var distAngle2 = Hacks.AF - distAngle1;
    var rtarget = (distAngle1 < distAngle2 ? target : (target < value ? target + Hacks.AF : target - Hacks.AF));
    return value = value = value * weight + rtarget * (1 - weight);
  }

  public function t(target:Float, ?instant:Bool = false):Void {
    this.target = target;
    if (instant) {
      value = target;
    }
  }

  public function d(delta:Float):Void {
    target += delta;
  }
}
