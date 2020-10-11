typedef TDTape = {
  n:Int,
  posX:Hyst,
  posY:Hyst,
  x:Int,
  y:Int,
  inserting:Int,
  inserted:Int,
  ejecting:Int,
};

class Tapedeck {
  public var pos = new Hyst(0);
  public var posBias = new Hyst(-8, -8, .93);
  public var open:Bool = true;
  public var y:Int = 0;
  public var doorOpen:Array<Bool> = [true, true];
  public var tapeState:Array<TapeState> = [Stop, Stop];
  public var tapeChannels:Array<Array<Sfx.SfxChannel>> = [[], []];
  public var tapeIn:Array<Int> = [-1, -1];
  public var doorPos:Array<Hyst> = [
    new Hyst(0, 0, .94),
    new Hyst(0, 0, .94),
  ];
  public var inventory:Array<TDTape> = [];
  var playPhase = [0, 0];

  public function new() {
    // collect(0);
    // collect(1);
    // collect(2);
    // collect(3);
  }

  public function collect(n:Int):Void {
    var y = 16 + inventory.length * 32;
    inventory.push({
      n: n,
      posX: new Hyst(-72, -48, .78),
      posY: new Hyst(y - 4, y, .78),
      x: 0,
      y: 0,
      inserting: -1,
      inserted: -1,
      ejecting: 0,
    });
  }

  public function render():Void {
    var hiding = R.gameOver || R.anyDialogue || inventory.length == 0;

    pos.t(hiding ? 16 : (open ? -56 : 0));
    posBias.t(open && pos.value < -50 ? 0 : -8);
    y = Std.int(pos.tick() + posBias.tick() + Ren.H);
    R.renderUI(0, y, getReg("tapedeckbg"));

    doorPos[0].t(doorOpen[0] ? 8 : 0);
    doorPos[1].t(doorOpen[1] ? 8 : 0);
    var doors = [ for (deck in 0...2) doorPos[deck].tickI() ];

    for (i in 0...inventory.length) {
      var t = inventory[i];
      var yTarget = y + 20;
      var ui = R.ui.tapes[R.ui.tapes.length - t.n - 1];
      var tx = hiding ? -72 : (ui.ix.hover ? -32 : -48);
      var ty = 16 + i * 32;
      var snappy = false;
      if (!ui.ix.held && t.inserting != -1) {
        // trace("inserted", t.n, t.inserting);
        tx = 1 + t.inserting * 74;
        ty = y + 12;
        t.inserted = t.inserting;
        doorOpen[t.inserting] = false;
        tapeIn[t.inserting] = t.n;
        snappy = true;
        Sfx.play("SFX_Cassette_5");
      } else if (t.inserted != -1 || t.ejecting > 0) {
        tx = 1 + t.inserted * 74;
        ty = y + 12 + (doorPos[t.inserted].value > 4 ? -Std.int((doorPos[t.inserted].value - 4) * 8) : 0);
        snappy = true;
        if (t.ejecting > 0) {
          t.ejecting++;
          if (t.ejecting >= 30) {
            t.ejecting = 0;
            t.inserted = -1;
          }
        }
      } else if (ui.ix.held) {
        tx = R.mouseX - 36;
        ty = R.mouseY - 24;
      }
      t.posX.t(tx, snappy);
      t.posY.t(ty, snappy);
      var rx = t.posX.tick();
      var ry = t.posY.tick();
      var yDist = yTarget - (ry + 48);
      if (ui.ix.held) {
        rx = rx.clamp(2, Ren.W - 72 - 2);
        ry = ry.clamp(2, Ren.H - 69); // !doorOpen[0] && !doorOpen[1] ? y - 48 : Ren.H - 69);
      }
      if (!doorOpen[0] && !doorOpen[1] && t.inserting == -1 && t.inserted == -1) ry = ry.clamp(0, y - 48);
      t.inserting = -1;
      if (t.inserted == -1 && yDist < 20) {
        var closestDeck = t.x + 36 < 74 ? 0 : 1;
        var fartherDeck = 1 - closestDeck;
        for (deck in [closestDeck, fartherDeck]) {
          var doorX = 1 + deck * 74;
          if (!doorOpen[deck]) continue;
          if (yDist < 4 && ui.ix.held) {
            // ImDebug.text("can insert into", '$deck');
            t.inserting = deck;
          }
          if (yDist < 0) yDist = 0;
          rx = (rx + 36).clamp(doorX + 36 - yDist, doorX + 36 + yDist) - 36;
          break;
        }
      }
      // ImDebug.text("tip", '$tip, $rx, $ry');
      t.x = Std.int(rx);
      t.y = Std.int(ry);
    }

    for (deck in 0...2) {
      var x = 1 + deck * 74;
      for (button in 0...4) {
        var ui = [
          R.ui.decks[deck].rew,
          R.ui.decks[deck].play,
          R.ui.decks[deck].fwd,
          R.ui.decks[deck].eject,
        ][button];
        var bx = x + button * 18;
        var by = y - 5;
        ui.x = bx;
        ui.y = by;
        var col = ui.ix.hover ? .9 : 1;
        var down = ui.ix.held;
        if (button == 0 && tapeState[deck] == Rew) down = true;
        if (button == 1 && tapeState[deck] == Play) down = true;
        if (button == 2 && tapeState[deck] == Fwd) down = true;
        R.renderUI(bx, by, getReg((down ? "tapedeckbuttondown" : "tapedeckbutton") + '-$button'), col, col, col);
      }
      var doorY = doors[deck];

      var ins = getReg("tapedeckinside");
      R.renderUIRaw(x + 3, y + 12 + 3 + doorY, ins.tx, ins.ty + doorY, ins.tw, ins.th, 1, 1, 1, 1);
    }
    for (i in 0...inventory.length) {
      var t = inventory[i];

      var deck = t.x + 36 < 74 ? 0 : 1;
      var doorX = 1 + deck * 74;
      var doorY = doors[deck];
      var tip = (t.y - 12) - (doorY + y);

      var ui = R.ui.tapes[R.ui.tapes.length - t.n - 1];
      ui.active = t.ejecting == 0 && t.inserted == -1;
      ui.x = t.x;
      ui.y = t.y;
      ui.ix.rename('Tape #${t.n + 1}');

      var col = ui.ix.hover ? .9 : 1;
      R.renderUI(t.x, t.y, getReg("tapedecktape"), col, col, col);
      var tin = getReg("tapedecktapein");
      //ImDebug.text("tip", '$tip ${doorY + y} ${t.y - 12}');
      //var tip = doorPos[deck].value > 4 ? -Std.int((doorPos[deck].value - 4) * 8) : 0;
      if (tip <= 0) {
        if (tip < -tin.th) tip = -tin.th;
        R.renderUIRaw(doorX + 1, y + 12 + doorY, tin.tx, tin.ty - tip, tin.tw, tin.th + tip, 1, 1, 1, 1);
      }
    }
    for (deck in 0...2) {
      var x = 1 + deck * 74;
      var doorY = doors[deck];
      R.renderUI(x, y + 12 + doorY, getReg('tapedeckdoor-$deck'));
      if (tapeState[deck] != Stop && tapeIn[deck] != -1) {
        var fr = (playPhase[deck] >> 3) % 4;
        R.renderUI(x + 12, y + 12 + 11, getReg('tapeplay-$fr'));
        if (playPhase[deck] % 15 == 0) {
          if (tapeState[deck] == Rew) {
            if (R.musicPuzzle.tapePos[tapeIn[deck]] <= 0) {
              Sfx.play("SFX_Cassette_3");
              tapeState[deck] = Stop;
            } else {
              R.musicPuzzle.tapePos[tapeIn[deck]]--;
            }
          }
          if (tapeState[deck] == Fwd) {
            if (R.musicPuzzle.tapePos[tapeIn[deck]] >= MusicPuzzle.SEQS[tapeIn[deck]].length - 1) {
              Sfx.play("SFX_Cassette_3");
              tapeState[deck] = Stop;
            } else {
              R.musicPuzzle.tapePos[tapeIn[deck]]++;
            }
          }
        }
        playPhase[deck]++;
      } else {
        playPhase[deck] = 0;
      }
      if (tapeIn[deck] != -1) {
        for (t in inventory) {
          if (t.n == tapeIn[deck]) {
            Text.render(x + 2, y + 22 + Std.int(doorPos[deck].value * 9), '${R.musicPuzzle.tapePos[t.n] + 1}', 0x705d54, 1000.);
            Text.render(x + 5, y + 36 + Std.int(doorPos[deck].value * 9), '${MusicPuzzle.SEQS[t.n].length}', 0x705d54, 1000.);
            break;
          }
        }
      }
    }
  }

  public function stop(deck:Int):Void {
    Sfx.play("SFX_Cassette_2");
    tapeState[deck] = Stop;
    for (c in tapeChannels[deck]) {
      c.fadeOut(100);
    }
    tapeChannels[deck].resize(0);
  }

  public function playReal(deck:Int):Void {
    tapeState[deck] = Play;
    // Sfx.play("tape0", 0);
    var ch = Sfx.play('Music_Tape_${tapeIn[deck] + 1}', 0);
    ch.pos(deck == 0 ? -1 : 1, 0, -1);
    if (R.musicPuzzle.tapePos[tapeIn[deck]] != 0) {
      ch.seek(R.musicPuzzle.tapePos[tapeIn[deck]] * MusicPuzzle.BEAT_LEN / 1000.);
      ch.fadeIn(80);
    }
    tapeChannels[deck].resize(0);
    tapeChannels[deck].push(ch);
  }

  public function play(deck:Int):Void {
    if (tapeIn[deck] == -1) return;
    if (tapeState[deck] == Play) {
      Sfx.play("SFX_Cassette_2");
      stop(deck);
    } else {
      stop(deck);
      playReal(deck);
    }
  }

  public function rew(deck:Int):Void {
    if (tapeIn[deck] == -1) return;
    var o = tapeState[deck];
    stop(deck);
    Sfx.play("SFX_Cassette_2");
    tapeState[deck] = (o == Rew ? Stop : Rew);
  }

  public function fwd(deck:Int):Void {
    if (tapeIn[deck] == -1) return;
    var o = tapeState[deck];
    stop(deck);
    Sfx.play("SFX_Cassette_2");
    tapeState[deck] = (o == Fwd ? Stop : Fwd);
  }

  public function eject(deck:Int):Void {
    if (!doorOpen[deck]) {
      Sfx.play("SFX_Cassette_4");
      if (tapeIn[deck] != -1) {
        for (t in inventory) {
          if (t.n == tapeIn[deck]) {
            t.ejecting = 1;
            t.inserting = -1;
            break;
          }
        }
        tapeIn[deck] = -1;
      }
      doorOpen[deck] = !doorOpen[deck];
      stop(deck);
    }
  }

  public function stopAll():Void {
    stop(0);
    stop(1);
  }
}

enum TapeState {
  Stop;
  Play;
  Rew;
  Fwd;
}
