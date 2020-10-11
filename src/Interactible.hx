class Interactible {
  public static function click(f:Void->Void):Interactible {
    return new Interactible((ix, held) -> {
      if (!held) f();
    }, null);
  }

  public static function hold(f:Void->Void):Interactible {
    return new Interactible(null, (ix) -> {
      if (ix.held) f();
    });
  }

  public var name:String;
  public var cursor:Cursor = Normal;
  public var hover:Bool = false;
  public var held:Bool = false;
  public var highlights:Bool = true;
  public var detail:Int = 0;
  public var sfxDown:String = null;
  public var sfxUp:String = null;
  var fnHeld:(Interactible, Bool)->Void;
  var fnTick:Interactible->Void;

  public function new(fnHeld:(Interactible, Bool)->Void, fnTick:Interactible->Void) {
    this.fnHeld = fnHeld;
    this.fnTick = fnTick;
  }

  public function mHeld(held:Bool):Void {
    if (held && sfxDown != null) Sfx.play(sfxDown);
    if (!held && sfxUp != null) Sfx.play(sfxUp);
    this.held = held;
    if (fnHeld != null) fnHeld(this, held);
  }

  public function tick():Void {
    if (fnTick != null) fnTick(this);
  }

  public function cur(cursor:Cursor):Interactible {
    this.cursor = cursor;
    return this;
  }

  public function rename(name:String):Interactible {
    this.name = name;
    return this;
  }

  public function detailed(detail:Int):Interactible {
    this.detail = detail;
    return this;
  }

  public function sfxDowned(id:String):Interactible {
    this.sfxDown = id;
    return this;
  }

  public function sfxUped(id:String):Interactible {
    this.sfxUp = id;
    return this;
  }
}
