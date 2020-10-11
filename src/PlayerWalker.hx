class PlayerWalker {
  public var player:Vis;
  public var current:{ax:Float, ay:Float, dx:Float, dy:Float, prog:Float, len:Float} = null;
  var queue:Array<{ax:Float, ay:Float, dx:Float, dy:Float}> = [];
  var phase = 0;
  var walkWakeup:Void->Void;
  var walkKind:Array<Vis.VisKind> = [
    RotoSprite([ for (i in 0...10) getReg('playerlegs-$i') ]),
    RotoSprite([ for (i in 0...10) getReg('playerlegsR-$i') ]),
    RotoSprite([ for (i in 0...10) getReg('playerlegs-$i') ]),
    RotoSprite([ for (i in 0...10) getReg('playerlegsL-$i') ]),
  ];

  public function new(player:Vis) {
    this.player = player;
  }

  public function walk(path:Array<{ax:Float, ay:Float, dx:Float, dy:Float}>, ?walkWakeup:Void->Void):Void {
    this.walkWakeup = walkWakeup;
    path.reverse();
    queue = path;
    queue.push(null);
  }

  public function clear():Void {
    current = null;
    queue = [];
  }

  var step = 0;
  var ssound = 0;

  public function tick():Void {
    var lop = 0.;
    if (current != null) {
      player.x = current.ax - (1 - current.prog / current.len) * current.dx;
      player.y = current.ay - (1 - current.prog / current.len) * current.dy;
      if (current.dx > 0) {
        if (current.dy > 0) {
          player.angle = AO;
        } else if (current.dy < 0) {
          player.angle = 3 * AO;
        } else {
          player.angle = AQ;
        }
      } else if (current.dx < 0) {
        if (current.dy > 0) {
          player.angle = -AO;
        } else if (current.dy < 0) {
          player.angle = -3 * AO;
        } else {
          player.angle = -AQ;
        }
      } else {
        if (current.dy > 0) {
          player.angle = 0;
        } else {
          player.angle = AH;
        }
      }
      current.prog += 1 + queue.length / 20.;
      if (current.prog >= current.len) {
        player.x = current.ax;
        player.y = current.ay;
        lop = current.prog - current.len;
        current = null;
      }
    }
    if (current == null && queue.length > 0) {
      var q = queue.shift();
      if (step++ % 5 == 0) {
        Sfx.play('SFX_Step_${1 + (ssound++ % 2)}');
      }
      if (q == null) {
        if (/*queue.length == 0 && */walkWakeup != null) {
          walkWakeup();
          walkWakeup = null;
        }
      } else {
        current = {
          ax: q.ax,
          ay: q.ay,
          dx: q.dx,
          dy: q.dy,
          prog: lop,
          len: (q.dx != 0 && q.dy != 0 ? 7.07 : 5),
        };
      }
    }
    if (current == null) phase = 0;
    else phase++;
    player.sub[0].kind = walkKind[(phase >> 3) % 4];
  }
}
