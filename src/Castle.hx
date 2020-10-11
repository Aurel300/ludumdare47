class Castle {
  final SCALE_XY = 31.5;
  final SCALE_Z = 24;

  public var floors:Array<Floor>;
  public var roomMap:Map<String, Room>;
  public var root:Vis;

  public function new() {
    root = new Vis(null);
    root.add(Vis.makePlayer("player"));
    floors = [];
    roomMap = [];
    var rooms:Array<Room> = [];
    function floor(number:Int, f:Void->Void):Void {
      f();
      var vis = new Vis('floor$number').at(0, 0, (number - 1) * -SCALE_Z, 0);
      var floor = ({
        number: number,
        rooms: rooms,
        vis: vis,
      }:Floor);
      for (room in rooms) {
        room.floor = floor;
        vis.add(room.vis);
      }
      root.add(vis);
      floors.push(floor);
      vis.light = new Hyst(0, 0, .97);
      rooms.resize(0);
    }
    var parts:Array<Vis> = [];
    function room(name:String, id:String, f:Void->Void, ?shows:Array<String>):Void {
      f();
      var vis = new Vis(name.split(" ")[1]);
      vis.light.t(0);
      vis.active = false;
      for (part in parts) vis.add(part);
      var room = new Room(name, id, vis, shows);
      function walk(v:Vis):Void {
        v.room = room;
        for (s in v.sub) walk(s);
      }
      walk(vis);
      room.updatePaths();
      roomMap[id] = room;
      rooms.push(room);
      parts.resize(0);
    }
    function segment(id:String, ox:Int, oy:Int):Void {
      parts.push(Vis.makeRoom(id, id).at(ox * SCALE_XY, oy * SCALE_XY, 0, 0));
    }
    floor(1, () -> {
      room("The Dawn room", "1a", () -> {
        segment("1a1", -3, -3);
        VM["1a1/wall1"].add(Vis.makeWall("1a/plaque1", "plaque").at(20, 1.5, 8, 0));
        VM["1a1/wall1"].add(Vis.makeCylinderHalf("1a/face", "face1", 7, "face1inside").at(80, 0.5, 0, 0));
        VM["1a1/wall3"].add(Vis.makeWall("1a/door1", "door1").at(80, 1.5, 0, 0));
        VM["1a/door1"].add(Vis.makeWall(null, "door1big").at(0, 1, 0, 0).scaled(.33333).alphad(0));
        VM["1a1/wall3"].add(Vis.makeWall("1a/tapeholder", "tapeholdopen").at(20, 1.5, 7, 0));
        VM["1a/tapeholder"].add(Vis.makeCassette("1a/tape1").at(16, -3, 3.5, 0).scaled(0.35));
        VM["1a/tapeholder"].hidesSubs = true;
        VM["1a1/wall4"].add(Vis.makeWall("1a/plaque2", "plaque").at(20, 1.5, 8, 0).alphad(0));
      });
      room("The Noon room", "1b", () -> {
        segment("1b1", -3, -1);
        VM["1b1/wall2"].add(Vis.makeWall("1b/door1", "door1").at(80, 1.5, 0, 0));
        VM["1b/door1"].add(Vis.makeWall(null, "door1big").at(0, 1, 0, 0).scaled(.33333).alphad(0));
        VM["1b1/floor"].add(Vis.makeFloor("1b/trapdoor", "trapdoor").at(20, 85, 2, 0));
      }, ["2b"]);
      room("The Dusk room", "1c", () -> {
        segment("1c1", -1, 1);
        VM["1c1/wall1"].add(Vis.makeWall("1c/door1", "door1").at(80, 1.5, 0, 0));
        VM["1c1/wall1"].add(Vis.makeWall("1c/tapeholder", "tapeholdopen").at(20, 1.5, 7, 0));
        VM["1c/tapeholder"].add(Vis.makeCassette("1c/tape2").at(16, -3, 3.5, 0).scaled(0.35));
        VM["1c/tapeholder"].hidesSubs = true;
        VM["1c/door1"].add(Vis.makeWall(null, "door1big").at(0, 1, 0, 0).scaled(.33333).alphad(0));
        VM["1c1/wall3"].add(Vis.makeHolder("1c/rose", [
          Vis.makeWall("1c/rose/front", "rose-0").at(-32, 0, 0, 0),
          Vis.makeHolder("1c/rose/puzzle", [
            Vis.makeWall("1c/rose/puzzle/wall", "rose-1"),
            Vis.makeHolder("1c/rose/puzzle/0", [
              Vis.makeWall(null, "rosehook", true).at(0, 0, 0, 0).flipTexH(),
              Vis.makeBox(null, "roseweight-0").at(22, -4, -2, 0),
            ]).scaled(.5).at(12, 0, -4, .75 * -AH),
            Vis.makeHolder("1c/rose/puzzle/1", [
              Vis.makeWall(null, "rosehook", true).at(0, 0, 0, 0).flipTexH(),
              Vis.makeBox(null, "roseweight-1").at(22, -4, -4, 0),
            ]).scaled(.5).at(22, 0, -4, .75 * -AH),
            Vis.makeHolder("1c/rose/puzzle/2", [
              Vis.makeWall(null, "rosehook", true).at(0, 0, 0, 0).flipTexH(),
              Vis.makeBox(null, "roseweight-2").at(22, -4, -6, 0),
            ]).scaled(.5).at(32, 0, -4, .75 * -AH),
            Vis.makeHolder("1c/rose/puzzle/3", [
              Vis.makeWall(null, "rosehook", true).at(0, 0, 0, 0).flipTexH(),
              Vis.makeBox(null, "roseweight-3").at(22, -4, -8, 0),
            ]).scaled(.5).at(42, 0, -4, .75 * -AH),
            Vis.makeHolder("1c/rose/puzzle/4", [
              Vis.makeWall(null, "rosehook", true).at(0, 0, 0, 0).flipTexH(),
              Vis.makeBox(null, "roseweight-4").at(22, -4, -10, 0),
            ]).scaled(.5).at(52, 0, -4, .75 * -AH),
          ]).at(32, 0, 0, AH),
        ]).at(39, 0, 6, 0));
        VM["1c/rose/puzzle"].active = false;
        VM["1c1/wall3"].add(Vis.makeWall("1c/plaque1", "plaque").at(90, 1.5, 8, 0));
      });
      room("The Night room", "1d", () -> {
        segment("1d1", 1, -3);
        VM["1d1/wall1"].add(Vis.makeWall("1d/button", "button").at(40, 1.5, 4, 0));
        VM["1d1/wall2"].add(Vis.makeWall("1d/tapeholder", "tapeholdopen").at(40, 1.5, 7, 0).alphad(0));
        VM["1d/tapeholder"].add(Vis.makeCassette("1d/tape3").at(16, -3, 3.5, 0).scaled(0.35));
        VM["1d/tapeholder"].hidesSubs = true;
        VM["1d1/wall2"].add(Vis.makeHolder("1d/buttons", [
          Vis.makeWall("1d/buttons/b0", "smallbutton-0").at(0, 0, 0, 0),
          Vis.makeWall("1d/buttons/b1", "smallbutton-1").at(16, 0, 0, 0),
          Vis.makeWall("1d/buttons/b2", "smallbutton-2").at(32, 0, 0, 0),
        ]).at(76, 1.5, 6, 0));
        VM["1d1/wall4"].add(Vis.makeWall("1d/door1", "door1").at(80, 1.5, 0, 0));
        VM["1d/door1"].add(Vis.makeWall(null, "door1big").at(0, 1, 0, 0).scaled(.33333).alphad(0));
        VM["1d1/floor"].add(Vis.makeBox("1d/platform", "platform").at(26, 1, -22 - 24, 0));
        VM["1d/platform"].light.t(0.5);
      }, ["2a"]);
    });
    floor(2, () -> {
      room("The Hooked room", "2a", () -> {
        segment("2a1", -3, -5);
        segment("2a2", 1, -3);
      });
      room("The Twisted room", "2b", () -> {
        segment("2b1", -5, -1);
        segment("2b2", -5, 3);
      });
      room("The Spun room", "2c", () -> {
        segment("2c1", -1, 1);
        segment("2c2", 3, -1);
      });
    });
    /*
    floor(3, () -> {
      room("The Major room", "3a", () -> {
        segment("3a1", 1, -5);
        segment("3a2", -1, -3);
        segment("3a3", 1, -1);
      });
      room("The Augmented room", "3b", () -> {
        segment("3b1", -5, -5);
        segment("3b2", -3, -3);
      });
      room("The Minor room", "3c", () -> {
        segment("3c1", -3, 3);
        segment("3c2", -3, 1);
      });
      room("The Diminished room", "3d", () -> {
        segment("3d1", -1, 1);
        segment("3d2", 1, 3);
      });
    });
    */
  }
}

@:structInit
class Floor {
  public var number:Int;
  public var rooms:Array<Room>;
  public var vis:Vis;
}

class Room {
  public var name:String;
  public var id:String;
  public var vis:Vis;
  public var shows:Array<String>;
  public var floor:Floor;
  public var update:Void->Void = () -> {};

  public var walkX:Int;
  public var walkY:Int;
  public var walkW:Int;
  public var walkH:Int;
  var walkable:Vector<Bool>;
  var visited:Vector<Int>;
  //var dist:Vector<Float>;

  public function new(name:String, id:String, vis:Vis, ?shows:Array<String>) {
    this.name = name;
    this.id = id;
    this.vis = vis;
    this.shows = shows != null ? shows : [];
  }

  final DBG_ID = null; // "1a";

  function closest(x:Float, y:Float):Int {
    var ix = Std.int((x + 2/* - walkX*/) / 4);
    var iy = Std.int((y + 2/* - walkY*/) / 4);
    if (ix < 0) ix = 0;
    if (ix >= walkW) ix = walkW;
    if (iy < 0) iy = 0;
    if (iy >= walkH) iy = walkH;
    return ix + iy * walkW;
  }

  function pathTo(sx:Float, sy:Float, tx:Float, ty:Float):Array<{
    ax:Float,
    ay:Float,
    dx:Float,
    dy:Float,
  }> {
    var start = closest(sx, sy);
    var target = closest(tx, ty);
    ImDebug.text("from", '${start % walkW}, ${Std.int(start / walkW)}');
    ImDebug.text("to", '${target % walkW}, ${Std.int(target / walkW)}');
    var queue = [start];
    for (i in 0...visited.length) {
      visited[i] = -1;
      //dist[i] = 0;
    }
    while (queue.length > 0) {
      var pos = queue.shift();
      if (pos == target) {
        var cur = pos;
        return [ while (cur != start) {
          var prev = visited[cur];
          var cx = cur % walkW;
          var cy = Std.int(cur / walkW);
          var dx = cx - (prev % walkW);
          var dy = cy - Std.int(prev / walkW);
          cur = prev;
          {
            ax: (cx + walkX) * 4,
            ay: (cy + walkY) * 4,
            dx: dx * 4,
            dy: dy * 4
          };
        } ];
      }
      // var pdist = dist[pos];
      var px = pos % walkW;
      var py = Std.int(pos / walkW);
      for (n in [
        {ox:  0, oy: -1, d: 1.00},
        {ox: -1, oy:  0, d: 1.00},
        {ox:  1, oy:  0, d: 1.00},
        {ox:  0, oy:  1, d: 1.00},
        {ox: -1, oy: -1, d: 1.47},
        {ox:  1, oy: -1, d: 1.47},
        {ox: -1, oy:  1, d: 1.47},
        {ox:  1, oy:  1, d: 1.47},
      ]) {
        var nxtX = px + n.ox;
        var nxtY = py + n.oy;
        var nxt = nxtX + nxtY * walkW;
        if (nxtX < 0 || nxtX >= walkW || nxtY < 0 || nxtY >= walkH || !walkable[nxt]) {
          continue;
        }
        //var nd = pdist + n.d;
        if (visited[nxt] != -1) { // && dist[nxt] <= nd) {
          continue;
        }
        visited[nxt] = pos;
        //dist[nxt] = nd;
        queue.push(nxt);
      }
    }
    return [];
  }

  public function walkTo(tx:Float, ty:Float, ?walkWakeup:Void->Void):Void {
    R.playerWalker.walk(pathTo(
      R.player.x - walkX * 4,
      R.player.y - walkY * 4,
      tx,
      ty
    ), walkWakeup);
  }

  public function updatePaths():Void {
    var minX = 1000.;
    var minY = 1000.;
    var maxX = -1000.;
    var maxY = -1000.;
    for (part in vis.sub) {
      var floor = part.sub[0];
      floor.ix = Interactible.click(() -> {
        walkTo(
          R.mouseTargetX.clamp(.1, .9) * floor.w,
          R.mouseTargetY.clamp(.1, .9) * floor.h
        );
      });
      floor.ix.highlights = false;
      if (part.x < minX) minX = part.x;
      if (part.y < minY) minY = part.y;
      if (part.x + floor.w > maxX) maxX = part.x + floor.w;
      if (part.y + floor.h > maxY) maxY = part.y + floor.h;
    }
    walkX = Std.int(minX) >> 2;
    walkY = Std.int(minY) >> 2;
    walkW = Std.int(maxX - minX) >> 2;
    walkH = Std.int(maxY - minY) >> 2;
    walkable = new Vector<Bool>(walkW * walkH);
    visited = new Vector<Int>(walkW * walkH);
    //dist = new Vector<Float>(walkW * walkH);
    for (i in 0...walkable.length) {
      walkable[i] = true;
      visited[i] = -1;
      //dist[i] = 0;
    }
    if (id == DBG_ID) trace(walkX, walkY, walkW, walkH);
    function stamp(x:Float, y:Float, ?radius:Float = 1.):Void {
      if (id == DBG_ID) trace("Stamp", x, y);
      var cx = x / 4;
      var cy = y / 4;
      for (ix in Math.floor(cx - radius)...Math.ceil(cx + radius))
      for (iy in Math.floor(cy - radius)...Math.ceil(cy + radius)) {
        if (ix >= walkX && iy >= walkY && ix < walkX + walkW && iy < walkY + walkH) {
          walkable[(ix - walkX) + (iy - walkY) * walkW] = false;
        }
      }
    }
    function visit(v:Vis, depth:Int, wX:Float, wY:Float, wZ:Float, wA:Float, wM:Float):Void {
      var wC = Math.cos(wA);
      var wS = Math.sin(wA);
      if (v.id != "player" && v.obstructs && depth >= 3) {
        switch (v.kind) {
          case Wall:
            if (id == DBG_ID) trace("wall stamp", v.id);
            //if (v.id != null && v.id.startsWith("1a/face"))
            var p = 0.;
            while (p < v.w) {
              stamp(
                wX + (p * wC) * wM,
                wY + (-p * wS) * wM
              );
              p += 2.5;
            }
          case _:
        }
      }
      if (v.obstructs) for (s in v.sub) {
        var ox = (s.x * wC + s.y * wS) * wM;
        var oy = (-s.x * wS + s.y * wC) * wM;
        visit(s, depth + 1, wX + ox, wY + oy, wZ + s.z * wM, (wA + s.angle + s.tmpAngle).clipAngle(), s.scale * wM);
      }
    }
    visit(vis, 0, 0, 0, 0, 0, 1);
    if (id == DBG_ID) {
      var total = 0;
      for (y in walkY...walkY + walkH)
      for (x in walkX...walkX + walkW) {
        if (walkable[(x - walkX) + (y - walkY) * walkW]) {
          total++;
          vis.sub[0].sub[0].add(Vis.makeFloor(null, "roseweight").at((x - walkX) * 4 - 2, (y - walkY) * 4 - 2, 2, 0));
        }
      }
      trace(id, total, walkW * walkH);
    }
    /*
      
      var w = floor.w;
      var h = floor.h;
      var ox = 2;
      var oy = 2;
      walkable = new Vector<Bool>((w >> 2) * (h >> 2));
      for (i in 0...grid.length) {
        walkable[i] = true;
      }
      function visit(v:Vis):Void {
        switch (v.kind) {
          
        }
        for (s in v.sub) visit(s);
      }
      for (s in part.sub) {
        
      }
    */
  }
}
