class Vis {
  public static var VIS_MAP:Map<String, Vis> = [];
  public static var VIS_ARR:Array<Vis> = [];

  public static function makeRoom(id:String, name:String):Vis {
    var reg = getReg(name);
    return Vis.makeHolder(id, [
      new Vis('$id/floor', Floor).reg(reg),
      new Vis('$id/wall1', Wall).tex(reg.tx, reg.ty - reg.height, reg.tw, reg.height).at(0, 0, 0, 0),
      new Vis('$id/wall2', Wall).tex(reg.tx + reg.tw, reg.ty, reg.height, reg.th).at(reg.tw - 1, 0, 0, -AQ).sized(reg.th, reg.height).rotTexCW(),
      new Vis('$id/wall3', Wall).tex(reg.tx, reg.ty + reg.th, reg.tw, reg.height).at(reg.tw - 1, reg.th - 1, 0, AH).flipTexVH(),
      new Vis('$id/wall4', Wall).tex(reg.tx - reg.height, reg.ty, reg.height, reg.th).at(0, reg.th - 1, 0, AQ).sized(reg.th, reg.height).rotTexCCW(),
    ]);
  }

  public static function makeBox(id:String, name:String):Vis {
    var reg = getReg(name);
    return Vis.makeHolder(id, [
      new Vis(id != null ? '$id/top' : null, Floor).reg(reg).at(0, 0, reg.height - 1, 0),
      new Vis(id != null ? '$id/wall1' : null, Wall).tex(reg.tx, reg.ty - reg.height, reg.tw, reg.height).at(reg.tw - 1, 0, 0, AH).flipTexV(),
      new Vis(id != null ? '$id/wall2' : null, Wall).tex(reg.tx + reg.tw, reg.ty, reg.height, reg.th).at(reg.tw - 1, reg.th - 1, 0, AQ).sized(reg.th, reg.height).rotTexCCW(),
      new Vis(id != null ? '$id/wall3' : null, Wall).tex(reg.tx, reg.ty + reg.th, reg.tw, reg.height).at(0, reg.th - 1, 0, 0).flipTexH(),
      new Vis(id != null ? '$id/wall4' : null, Wall).tex(reg.tx - reg.height, reg.ty, reg.height, reg.th).at(0, 0, 0, -AQ).sized(reg.th, reg.height).rotTexCW(),
    ]);
  }

  public static function makeCylinderHalf(id:String, name:String, parts:Int, ?iname:String):Vis {
    var root = new Vis(id);
    var reg = getReg(name);
    var radius = (reg.tw / AH) * .86;
    var pa = AH / parts;
    var pw = Std.int(reg.tw / parts);
    for (i in 0...parts) {
      var cpa = i * pa;
      var s = Math.sin(cpa);
      var c = Math.cos(cpa);
      root.add(new Vis('$id/cp$i', Wall)
        .tex(reg.tx + i * pw, reg.ty, pw, reg.th)
        .at(-c * radius, s * radius, 0, (i + 0.5) * pa - AQ));
    }
    if (iname != null) {
      var reg = getReg(iname);
      radius *= .96;
      for (i in 0...parts) {
        var cpa = (i + 1) * pa;
        var s = Math.sin(cpa);
        var c = Math.cos(cpa);
        root.add(new Vis('$id/icp$i', Wall)
          .tex(reg.tx + i * pw, reg.ty, pw, reg.th)
          .flipTexH()
          .at(-c * radius, s * radius, 0, (i + 0.5) * pa + AQ));
      }
    }
    return root;
  }

  public function updateCylinderHalf(name:String, parts:Int, ?iname:String):Vis {
    var reg = getReg(name);
    var pw = Std.int(reg.tw / parts);
    var subI = 0;
    for (i in 0...parts) {
      sub[subI++].tex(reg.tx + i * pw, reg.ty, pw, reg.th);
    }
    if (iname != null) {
      var reg = getReg(iname);
      for (i in 0...parts) {
        sub[subI++].tex(reg.tx + i * pw, reg.ty, pw, reg.th).flipTexH();
      }
    }
    return this;
  }

  public static function makeCassette(id:String):Vis {
    var layers = [
      makeBox(null, 'cassette-0').at(-36, -24, 0, 0),
      makeBox(null, 'cassette-1').at(-36, -24, 0, 0),
      makeBox(null, 'cassette-2').at(-36, -24, 0, 0),
    ];
    for (i in 1...layers.length) {
      layers[i].sub[0].z -= i * .7;
      layers[i].sub[1].y += i * .9;
      layers[i].sub[2].x -= i * .9;
      layers[i].sub[3].y -= i * 1.3;
      layers[i].sub[4].x += i * .9;
    }
    return makeHolder(id, layers);
  }

  public static function makePlayer(id:String):Vis {
    return makeHolder(id, [
      Vis.makeRotoSprite(null, "playerlegs").at(0, 0, 0, 0),
      Vis.makeRotoSprite(null, "playerbody").at(0, 0, 2, 0),
      Vis.makeRotoSprite(null, "playerhead").at(0, 0, 18, 0),
    ]);
  }

  public static function makeFloor(id:String, name:String):Vis {
    return new Vis(id, Floor).reg(getReg(name));
  }

  public static function makeWall(id:String, name:String, ?double:Bool = false):Vis {
    var ret = new Vis(id, Wall).reg(getReg(name));
    ret.doubleSided = double;
    return ret;
  }

  public function updateWall(name:String):Vis {
    reg(getReg(name));
    return this;
  }

  public static function makeSprite(id:String, name:String):Vis {
    return new Vis(id, Sprite).reg(getReg(name));
  }

  public static function makeRotoSprite(id:String, name:String, ?n:Int = 10):Vis {
    return new Vis(id, RotoSprite([ for (i in 0...n) getReg('$name-$i') ]));
  }

  public static function makeHolder(id:String, sub:Array<Vis>):Vis {
    var ret = new Vis(id);
    for (s in sub) ret.add(s);
    return ret;
  }

  public var id:String;
  public var name:String;
  public var active:Bool = true;
  public var parentActive:Bool = true;
  public var parentLight:Float = 1.;
  public var x:Float = 0;
  public var y:Float = 0;
  public var z:Float = 0;
  public var angle:Float = 0;
  public var scale:Float = 1;
  public var tmpX:Float = 0;
  public var tmpY:Float = 0;
  public var tmpZ:Float = 0;
  public var tmpAngle:Float = 0;
  public var wX:Float = 0; // cache
  public var wY:Float = 0;
  public var wZ:Float = 0;
  public var wA:Float = 0;
  public var wC:Float = 0;
  public var wS:Float = 0;
  public var wM:Float = 0;
  public var sub:Array<Vis> = [];
  public var kind:VisKind;
  public var w:Int = 0; // render size
  public var h:Int = 0;
  public var tx:Int = 0; // texture
  public var ty:Int = 0;
  public var twx:Int = 0;
  public var thx:Int = 0;
  public var twy:Int = 0;
  public var thy:Int = 0;
  public var visIndex:Int = 0;
  public var doubleSided:Bool = false;
  public var ix:Interactible;
  public var parentIx:Interactible;
  public var highlight = new Hyst(0, 0, .75);
  public var light = new Hyst(1);
  public var voiceColour:UInt = 0xffffff;
  public var room:Castle.Room;
  public var alpha = new Hyst(1);
  public var hidesSubs:Bool = false;
  public var zBias:Float = 0.;
  public var parentZBias:Float = 0.;
  public var zoomOZ:Float = 0.;
  public var obstructs:Bool = true;

  public function new(id:String, ?kind:VisKind = None) {
    this.id = id;
    this.kind = kind;
    if (id != null) {
      VIS_MAP[id] = this;
    }
    if (kind != None) {
      VIS_ARR.push(this);
    }
  }

  public function add(s:Vis):Vis {
    sub.push(s);
    return this;
  }

  public function at(x:Float, y:Float, z:Float, angle:Float):Vis {
    this.x = x;
    this.y = y;
    this.z = z;
    this.angle = angle;
    return this;
  }

  public function reg(reg:Region):Vis {
    tex(reg.tx, reg.ty, reg.tw, reg.th);
    return this;
  }

  public function tex(tx:Int, ty:Int, tw:Int, th:Int):Vis {
    this.tx = tx;
    this.ty = ty;
    this.twx = w = tw;
    this.thy = h = th;
    return this;
  }

  public function sized(w:Int, h:Int):Vis {
    this.w = w;
    this.h = h;
    return this;
  }

  public function scaled(scale:Float):Vis {
    this.scale = scale;
    return this;
  }

  public function alphad(alpha:Float):Vis {
    this.alpha.t(alpha, true);
    return this;
  }

  public function voiced(colour:UInt):Vis {
    this.voiceColour = colour;
    return this;
  }

  public function flipTexV():Vis {
    ty += thy;
    thy *= -1;
    return this;
  }

  public function flipTexH():Vis {
    tx += twx;
    twx *= -1;
    return this;
  }

  public function flipTexVH():Vis {
    flipTexV();
    flipTexH();
    return this;
  }

  public function rotTexCCW():Vis {
    var tw = twx;
    var th = thy;
    twx = 0;
    ty += th;
    twy = -th;
    thx = tw;
    thy = 0;
    return this;
  }

  public function rotTexCW():Vis {
    var tw = twx;
    var th = thy;
    twx = 0;
    twy = th;
    tx += tw;
    thx = -tw;
    thy = 0;
    return this;
  }

  public function rename(name:String, ?deep:Bool = false):Vis {
    this.name = name;
    for (s in sub) s.rename(name, true);
    return this;
  }

  public function deix():Interactible {
    var ret = ix;
    ix = null;
    return ret;
  }

  public function globalise():Vis {
    x = wX;
    y = wY;
    z = wZ;
    angle = wA;
    scale = wM;
    return this;
  }

  public function deglobalise(parent:Vis):Vis {
    //var wC = Math.cos(parent.wA);
    //var wS = Math.sin(parent.wA);
    //var ox = ((x) * wC + (y) * wS) * parent.wM;
    //var oy = (-(x) * wS + (y) * wC) * parent.wM;
    //wX = parent.wX + ox,
    //wY = parent.wY + oy,
    //wZ = parent.wZ + (z + tmpZ) * parent.wM,
    //wA = parent.wA + angle + tmpAngle,
    //wM = scale * parent.wM,

    // solve for x, y, z, angle, scale
    scale = wM / parent.wM;
    angle = wA - parent.wA;
    z = (wZ - parent.wZ) / parent.wM;
    var ox = (wX - parent.wX) / parent.wM;
    var oy = (wY - parent.wY) / parent.wM;

    var wC = Math.cos(-parent.wA);
    var wS = Math.sin(-parent.wA);
    x = ox * wC + oy * wS;
    y = -ox * wS + oy * wC;

    return this;
  }

  public function zoomPos():{x:Float, y:Float, z:Float} {
    var x = wX;
    var y = wY;
    var z = wZ;
    // var oa = wA + R.cameraAngle.value;
    var c = Math.cos(-wA);
    var s = Math.sin(-wA);
    switch (kind) {
      case Wall:
        x += c * (w / 2);
        y += s * (w / 2);
        z += h / 2;
      case Floor:
        x += c * (w / 2) + s * (h / 2);
        y += -s * (w / 2) + c * (h / 2);
      case _:
    }
    return {x: x, y: y, z: z + zoomOZ};
  }

  public function zoom(?zoom:Float = 2.5, ?offAngle:Float = 0.):Void {
    // trace("zoom", R.cameraStack.length, id);
    R.cameraStack.push({
      x: R.cameraX.target,
      y: R.cameraY.target,
      z: R.cameraZ.target,
      angle: R.cameraAngle.target,
      zoom: R.cameraZoom.target,
      target: R.cameraTarget,
      deckOpen: R.deck.open,
    });
    var pos = zoomPos();
    R.cameraX.t(pos.x);
    R.cameraY.t(pos.y);
    R.cameraZ.t(pos.z);
    R.cameraAngle.t(-wA + offAngle);
    R.cameraZoom.t(zoom);
    R.cameraTarget = this;
  }

  public function prerender(
    wX:Float, wY:Float, wZ:Float, wA:Float,
    ?parentActive:Bool = true, ?parentLight:Float = 1., ?parentZBias:Float = 0., ?highlight:Bool = false, ?wM:Float = 1., ?parentIx:Interactible
  ):Void {
    // light.t(Math.random());
    this.parentActive = parentActive;
    parentLight = light.tick() * parentLight;
    this.parentLight = parentLight;
    parentIx = ix != null && ix.detail == R.cameraStack.length ? ix : parentIx;
    this.parentIx = parentIx;
    highlight = highlight || (ix != null && ix.hover && ix.highlights);
    parentZBias += zBias;
    this.parentZBias = parentZBias;
    this.highlight.t(highlight ? 1 : 0);
    this.highlight.tick();
    this.wX = wX;
    this.wY = wY;
    this.wZ = wZ;
    this.wA = wA;
    this.wM = wM;
    switch (kind) {
      case RotoSprite(regs):
        this.wA = 0;
        var idx = Math.round(((wA + R.cameraAngle.value).clipAngle() + Hacks.AF) / (Hacks.AF / regs.length)) % regs.length;
        reg(regs[idx]);
      case Wall if (!doubleSided && hidesSubs):
        if (Math.abs(((wA + R.cameraAngle.value) % Hacks.AF).clipAngle()) >= AQ) {
          parentLight = 0.;
          parentIx = null;
        }
      case _:
    }
    wC = Math.cos(wA);
    wS = Math.sin(wA);
    if (sub.length != 0) {
      for (s in sub) {
        var ox = ((s.x + s.tmpX) * wC + (s.y + s.tmpY) * wS) * wM;
        var oy = (-(s.x + s.tmpX) * wS + (s.y + s.tmpY) * wC) * wM;
        s.prerender(
          wX + ox, wY + oy, wZ + (s.z + s.tmpZ) * wM,
          wA + s.angle + s.tmpAngle, parentActive && active, parentLight, parentZBias, highlight, s.scale * wM, parentIx
        );
      }
    }
  }

  public function renderFlats():Void {
    if (!active || !parentActive) return;
    switch (kind) {
      case Sprite | RotoSprite(_): inline R.renderSprite(this);
      case Floor: inline R.renderFloor(this);
      case Wall: inline R.renderWall(this);
      case _:
    }
  }
}

enum VisKind {
  None;
  Sprite;
  RotoSprite(regs:Array<Region>);
  Floor;
  Wall;
  Volume(height:Int);
}
