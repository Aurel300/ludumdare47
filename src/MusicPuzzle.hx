typedef Note = {
  beat:Int,
  pitch:Int,
  long:Bool,
  type:Int,

  age:Int,
};

class MusicPuzzle {
  public static var SEQS = {
    var h = -1;
    var q = -2;
    var base:Array<Array<Array<Int>>> = [
      [[0, h, 0, 0, 2, h, 3, h, 4, h]], // 10
      [[0, h, 4, h, h, q, 2, 3, 0, h, 0]], // 11
      [[0, h, 2, 3, 2, 3, 4, h, h]], // 9
      [[0, h, 3, 0, 1, 3, h]], // 7
    ];
    var combos:Array<Array<Array<Int>>> = [];
    function combo(sub:Array<{seq:Int, off:Int}>, len:Int):Void {
      var ret:Array<Array<Int>> = [ for (i in 0...sub.length) [] ];
      for (j in 0...sub.length) {
        var s = sub[j];
        var seq = base[s.seq][0];
        for (i in 0...len) {
          //ret[i].push(seq[(i + s.off) % seq.length]);
          var pos = i - s.off;
          if (pos >= 0 && pos < seq.length) {
            ret[j].push(seq[pos]);
          } else {
            ret[j].push(q);
          }
        }
      }
      /*
      for (s in sub) {
        var seq = base[s.seq][0];
        for (i in 0...len) {
          //ret[i].push(seq[(i + s.off) % seq.length]);
          var pos = i + s.off;
          if (pos >= 0 && pos < seq.length) {
            ret[i].push(seq[pos]);
          } else {
            ret[i].push(q);
          }
        }
      }
      */
      combos.push(ret);
    }
    combos.push([
      [2, h, 3, h, 4, h, 0, h, 0, 0]
    ]);
    combos.push([
      [q, q, q, q, 0, h, 0, 0],
      [0, h, 4, h, h, q, 2, 3],
    ]);
    //combo([{seq: 0, off: 1}, {seq: 1, off: 0}], 8);
    combo([{seq: 0, off: 0}, {seq: 3, off: 6}], 11);
    combo([{seq: 1, off: 0}, {seq: 1, off: 11}, {seq: 2, off: 5}], 19);
    //trace(combos[0]);
    [ for (seq in base.concat(combos)) {
      // var last = -2;
      [ for (i in 0...seq[0].length) {
        [ for (j in 0...seq.length) {
          if (seq[j][i] == q || seq[j][i] == h) 0x20;
          else {
            var long = seq[j][(i + 1) % seq[j].length] == h;
            seq[j][i] | (long ? 0x10 : 0);
          }
        } ];
      } ];
    } ];
  };

  public var tapePos:Array<Int> = [ for (s in SEQS) 0 ];

  public var show:Bool = false;
  public var showProg:Hyst = new Hyst(0, 0, .89);
  public var barAlpha:Hyst = new Hyst(0);
  public var barPos:Hyst = new Hyst(0, 0, .8);
  public var beatNum:Int = 0;
  public var targetSeq:Array<Array<Int>> = [];
  public var solveWakeup:Void->Void;
  public var betaWakeup:Void->Void;

  public var engraved:Array<Note> = [];
  public var eph:Array<Note> = [];

  static final QUIET = 0x20;
  static final LONG = 0x10;
  static final PITCH = 0xF;

  var ageMax = 1000; // TODO: bpm etc
  var ageSpread = 25;

  public function new() {
    
  }

  static function getNotes(seq:Array<Array<Int>>, i:Int):Array<Note> {
    return [ for (note in seq[i]) {
      if (note == QUIET) continue;
      var pitch = note & PITCH;
      var long = (note & LONG) != 0;
      {
        beat: i,
        pitch: pitch,
        long: long,
        type: 0,
        age: 0,
      };
    } ];
  }

  public function prepare(n:Int, solveWakeup:Void->Void):Void {
    // trace("preparing", n);
    targetSeq = SEQS[n];
    this.solveWakeup = solveWakeup;
    engraved = [];
    for (i in 0...targetSeq.length) {
      engraved = engraved.concat(getNotes(targetSeq, i));
    }
  }

  public static final BPM = 130.;
  public static final BPS = BPM / 60.;
  public static final BEAT_LEN = 1000. / BPS;

  var nextBeat = -1.;

  public function render():Void {
    var playing = R.deck.tapeState[0] == Play || R.deck.tapeState[1] == Play;
    var now = Date.now().getTime();
    if (!playing) {
      beatNum = 0;
      nextBeat = now + BEAT_LEN;
      for (n in eph) {
        if (n.age < ageMax - ageSpread) {
          n.age = ageMax - ageSpread;
        }
      }
    }
    if (nextBeat < 0) {
      nextBeat = now + BEAT_LEN;
    } else if (now >= nextBeat) {
      if (playing && show) {
        for (n in eph) {
          if (n.beat == beatNum && n.age < ageMax - ageSpread) {
            n.age = ageMax - ageSpread;
          }
        }
      }
      for (deck in 0...2) {
        if (R.deck.tapeState[deck] != Play) continue;
        var tape = R.deck.tapeIn[deck];
        var seq = SEQS[tape];
        var notes = getNotes(seq, tapePos[tape]);
        tapePos[tape]++;
        if (tapePos[tape] >= seq.length) {
          tapePos[tape] = 0;
          R.deck.playReal(deck);
          if (deck == 1 && betaWakeup != null) betaWakeup();
        }
        if (show) for (note in notes) {
          note.beat = beatNum;
          note.type = deck + 1;
          eph.push(note);
        }
      }
      beatNum++;
      if (targetSeq.length == 0) {
        beatNum = 0;
      } else if (beatNum >= targetSeq.length) {
        beatNum = 0;
        var solved = true;
        // trace("expecting", targetSeq);
        for (i in 0...targetSeq.length) {
          var cands = eph.filter(n -> n.beat == i && n.age < ageMax - ageSpread);
          var needNotes = getNotes(targetSeq, i);
          if (cands.length != needNotes.length) {
            // trace("mismatch in note count", i, cands.length, needNotes.length);
            // trace(eph);
            // trace(eph.map(n -> n.beat));
            // trace(eph.map(n -> n.beat == i));
            // trace(eph.map(n -> n.age < ageMax - ageSpread));
            solved = false;
            break;
          }
          var need = [0, 0, 0, 0, 0];
          var got = [0, 0, 0, 0, 0];
          for (n in needNotes) need[n.pitch] = n.long ? 2 : 1;
          for (n in cands) got[n.pitch] = n.long ? 2 : 1;
          for (j in 0...5) {
            if (need[j] != got[j]) {
              // trace("mismatch in beat", i, need, got);
              solved = false;
            }
          }
          if (!solved) break;
        }
        // trace("solved?", solved);
        if (solved) {
          // SFX
          if (solveWakeup != null) solveWakeup();
        }
      }
      nextBeat = now + BEAT_LEN;
    }

    //showProg.weight = show ? .98 : .85;
    showProg.t(show ? 1.1 : -0.3);
    showProg.tick();
    barAlpha.t(playing ? 1 : 0);
    if (showProg.value < -0.25) return;

    var bw = 160;
    var bx = ((Ren.W - bw) >> 1) - 5;
    var by = 14;
    var bxp = targetSeq.length == 0 ? 0 : (bw / targetSeq.length);
    var byp = 32;
    inline function showNote(note:Note, alpha:Float):Void {
      R.renderUI(
        Std.int(bx + bxp * note.beat),
        by + (4 - note.pitch) * byp,
        getReg(note.long ? 'notelong-${note.type}' : 'noteshort-${note.type}'),
        1, 1, 1, alpha
      );
    }
    for (note in engraved) {
      showNote(note, (showProg.value * targetSeq.length - note.beat).clamp(0, 1));
    }
    eph = [ for (note in eph) {
      showNote(note, note.age < ageSpread ? note.age / ageSpread : (note.age >= ageMax - ageSpread ? 1 - (note.age - (ageMax - ageSpread)) / ageSpread : 1));
      note.age++;
      if (note.age >= ageMax)
        continue;
      note;
    } ];
    barPos.t(beatNum * bxp);
    R.renderUI(
      bx + barPos.tickI(),
      by - 6,
      getReg("notebar"),
      1, 1, 1, barAlpha.tick()
    );
  }
}
