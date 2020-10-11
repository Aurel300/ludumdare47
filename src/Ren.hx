import glewb.Glewb.ctx;
import js.html.webgl.GL;

typedef RText = {
  x:Int,
  y:Int,
  msg:{
    text:String,
    width:Int,
    height:Int,
  },
  colour:UInt,
  visTarget:Vis,
  prog:Int,
};

typedef RAnim = {
  prog:Int,
  len:Int,
  f:Float->Void,
  done:Void->Void,
  blocking:Bool,
};

class Ren {
  public static final W:Int = 300;
  public static final H:Int = 240;
  public static final WH:Int = 150;
  public static final HH:Int = 120;
  final ZX = 2 / Math.cos(Math.atan(0.5));
  final ZY = 1 / Math.sin(Math.atan(0.5));

  public static var I:Ren;

  public var castle:Castle;
  public var effectVis:Vis;
  public var deck:Tapedeck;
  public var musicPuzzle:MusicPuzzle;
  public var player:Vis;
  public var playerWalker:PlayerWalker;
  public var plotStarted:Bool = false;
  public var currentRoom:Castle.Room;

  // rendering
  public var shader:shade.Shader;
  var surf:Surface;
  var readBuf:js.lib.Uint8Array;
  var tex:Texture;
  var vertexCount:Int;

  // camera
  public var cameraX = new Hyst(0);
  public var cameraY = new Hyst(-64);
  public var cameraZ = new Hyst(0);
  public var cameraAngle = new Hyst(0, 0.2853981633, .95);
  public var cameraZoom = new Hyst(.8/* 1 */);
  public var cameraTarget:Vis;
  public var cameraStack:Array<{
    x:Float,
    y:Float,
    z:Float,
    angle:Float,
    zoom:Float,
    target:Vis,
    deckOpen:Bool,
  }> = [];
  var zoomX:Float = 1;
  var zoomY:Float = 1;

  // ui and interaction
  var uiArr:Array<UI>;
  public var ui:{
    progressDialogue:UI,
    choices:Array<UI>,
    cancel:UI,
    goBack:UI,
    tapes:Array<UI>,
    decks:Array<{
      rew:UI,
      play:UI,
      fwd:UI,
      eject:UI,
    }>,
    turnLeft:UI,
    turnRight:UI,
    system:{
      sfx:UI,
      music:UI,
      fullscreen:UI,
    },
  } = null;
  public var texts:Array<RText> = [];
  public var dialogueWakeup:Void->Void;
  public var choices:Array<{
    msg:String,
    choice:Int,
  }>;
  public var choiceWakeup:Int->Void;
  public var cancelWakeup:Void->Void;
  public var beatWait:Bool = false;
  public var anyDialogue:Bool = false;
  public var cancelText:String;
  public var anim:Array<RAnim> = [];
  public var mouseX:Int = 0;
  public var mouseY:Int = 0;
  public var mouseTargetX:Float = 0.;
  public var mouseTargetY:Float = 0.;
  public var mOverVis:Vis;
  public var mOverUI:UI;
  public var mOverIx:Interactible;
  public var mHeldIx:Interactible;
  public var gameOver:Bool = false;
  public var gameOverRestart:Bool = false;
  var tooltipText:String = "";
  var tooltipPos = new Hyst(0);
  var faucet = 0;
  #if ITCHIO
  public var canvasWidth = 600;
  public var canvasHeight = 480;
  #end

  public function new(canvas:js.html.CanvasElement) {
    I = this;
    shader = new shade.Shader();
    surf = Surface.ofCanvas(canvas);
    readBuf = new js.lib.Uint8Array(4);
    #if ITCHIO
    Main.input.mouse.move.on(e -> mouseMove(Std.int((e.x / canvasWidth) * 300), Std.int((e.y / canvasHeight) * 240)));
    Main.input.mouse.down.on(e -> mouseDown(Std.int((e.x / canvasWidth) * 300), Std.int((e.y / canvasHeight) * 240)));
    Main.input.mouse.up.on(e -> mouseUp(Std.int((e.x / canvasWidth) * 300), Std.int((e.y / canvasHeight) * 240)));
    #else
    Main.input.mouse.move.on(e -> mouseMove(Std.int(e.x) >> 1, Std.int(e.y) >> 1));
    Main.input.mouse.down.on(e -> mouseDown(Std.int(e.x) >> 1, Std.int(e.y) >> 1));
    Main.input.mouse.up.on(e -> mouseUp(Std.int(e.x) >> 1, Std.int(e.y) >> 1));
    #end
    uiArr = [];
    deck = new Tapedeck();
    musicPuzzle = new MusicPuzzle();
    function u(x:Int, y:Int, w:Int, h:Int, ix:Interactible):UI {
      var ret = new UI(x, y, w, h, ix);
      uiArr.push(ret);
      return ret;
    }
    ui = {
      system: {
        sfx: u(W - 16, 0, 16, 16, Interactible.click(() -> Sfx.toggle()).rename("Toggle sound effects")),
        music: u(W - 32, 0, 16, 16, Interactible.click(() -> Sfx.toggleM()).rename("Toggle music")),
        fullscreen: null,
      },
      progressDialogue: u(0, 0, W, H, Interactible.click(() -> {
        if (dialogueWakeup != null && texts.length > 0 && texts[0].prog < texts[0].msg.text.length * 2) {
          texts[0].prog = texts[0].msg.text.length * 2;
        } else {
          dialogueWakeup();
        }
      }).rename("Click to continue").sfxUped("SFX_UI_Click")),
      choices: [
        for (i in 0...8)
          u(0, H, W, 12, Interactible.click(() -> choiceWakeup(choices[i].choice)).rename("").sfxUped("SFX_UI_Click")),
      ],
      tapes: [ for (ti in 0...10) u(-100, 0, 72, 48, Interactible.click(() -> {}).cur(Drag).sfxDowned("SFX_Cassette_4")) ],
      decks: [ for (di in 0...2) {
        var deckName = ["A", "B"][di];
        {
          rew: u(0, 0, 18, 15, Interactible.click(() -> deck.rew(di)).cur(Action).rename('Rewind tape $deckName').sfxDowned("SFX_Cassette_1")),
          play: u(0, 0, 18, 15, Interactible.click(() -> deck.play(di)).cur(Action).rename('Play/pause tape $deckName').sfxDowned("SFX_Cassette_1")),
          fwd: u(0, 0, 18, 15, Interactible.click(() -> deck.fwd(di)).cur(Action).rename('Fast forward tape $deckName').sfxDowned("SFX_Cassette_1")),
          eject: u(0, 0, 18, 15, Interactible.click(() -> deck.eject(di)).cur(Action).rename('Eject tape $deckName').sfxDowned("SFX_Cassette_1")),
        };
      } ],
      cancel: u(0, 0, W, H, Interactible.click(() -> {
        if (cancelWakeup != null) cancelWakeup();
        cancelWakeup = null;
      }).rename("Cancel").sfxUped("SFX_UI_Click2")),
      goBack: u(0, 0, W, H, Interactible.click(unzoom).cur(GoBack).rename("Go back").sfxUped("SFX_UI_Click2")),
      turnLeft: u(0, 0, 36, H, Interactible.hold(() -> cameraAngle.d(0.05)).cur(TurnLeft).rename("Turn camera left")),
      turnRight: u(W - 24, 0, 24, H, Interactible.hold(() -> cameraAngle.d(-0.05)).cur(TurnRight).rename("Turn camera right")),
    };
    for (t in ui.tapes) t.active = false;
    Debug.command("detail", w -> VM[w[1]].zoom());
  }

  public function updateAssets():Void {
    Region.init(Asset.ids["game.json"].text);
    tex = Asset.ids["game.png"].image;
    shader.flats.U.texture.bindTexture(tex, 0);
    shader.flats.U.textureSize.writeF32([tex.width, tex.height]);
    shader.ui.U.texture.bindTexture(tex, 0);
    shader.ui.U.textureSize.writeF32([tex.width, tex.height]);

    if (castle == null) {
      makeCastle();
    }
  }

  public function makeCastle():Void {
    Vis.VIS_MAP = [];
    Vis.VIS_ARR = [];
    castle = new Castle();
    effectVis = new Vis(null);
    cameraTarget = player = VM["player"];
    playerWalker = new PlayerWalker(player);
    //if (!plotStarted) { // TODO: redundant
      Plot.start();
      plotStarted = true;
      //enterRoom("1d", 32, 32); // !DEBUG
      enterRoom("1a", 64, 32);
    //}
  }

  public function reset():Void {
    makeCastle();
    cameraStack = [];
    cameraX.t(0, true);
    cameraY.t(-64, true);
    cameraZ.t(0, true);
    cameraAngle.t(0, true);
    cameraAngle.t(0.2853981633);
    cameraZoom.t(.8, true);
    texts = [];
    dialogueWakeup = null;
    choices = null;
    choiceWakeup = null;
    cancelWakeup = null;
    beatWait = false;
    anyDialogue = false;
    cancelText = null;
    anim = [];
    mouseX = 0;
    mouseY = 0;
    mouseTargetX = 0;
    mouseTargetY = 0;
    mOverVis = null;
    mOverUI = null;
    mOverIx = null;
    mHeldIx = null;
    gameOver = false;
    gameOverRestart = false;
    deck = new Tapedeck();
    musicPuzzle = new MusicPuzzle();
  }

  public function mouseMove(mx:Int, my:Int):Void {
    mouseX = mx;
    mouseY = my;
  }

  public function mouseDown(mx:Int, my:Int):Void {
    mHeldIx = mOverIx;
    if (mHeldIx != null) {
      mHeldIx.mHeld(true);
    }
    mouseX = mx;
    mouseY = my;
  }

  public function mouseUp(mx:Int, my:Int):Void {
    if (gameOverRestart) {
      reset();
      return;
    }
    if (mHeldIx != null) {
      mHeldIx.mHeld(false);
      mHeldIx = null;
      // SFX
    }
    mouseX = mx;
    mouseY = my;
  }

  public function unzoom():Void {
    // trace("unzoom", cameraStack.length, cameraTarget != null ? cameraTarget.id : "-");
    if (cameraStack.length < 1) return;
    var s = cameraStack.pop();
    cameraX.t(s.x);
    cameraY.t(s.y);
    cameraZ.t(s.z);
    cameraAngle.t(s.angle);
    cameraZoom.t(s.zoom);
    cameraTarget = s.target;
    deck.open = s.deckOpen;
  }

  public function enterRoom(target:String, x:Float, y:Float):Void {
    if (currentRoom != null) {
      currentRoom.floor.vis.light.t(0.4);
      currentRoom.vis.light.t(0.5);
      for (s in currentRoom.shows) {
        var s = castle.roomMap[s];
        s.vis.light.t(0);
      }
    }
    currentRoom = castle.roomMap[target];
    currentRoom.floor.vis.light.t(1);
    currentRoom.vis.light.t(1);
    currentRoom.vis.active = true;
    currentRoom.update();
    for (s in currentRoom.shows) {
      var s = castle.roomMap[s];
      if (s.floor != currentRoom.floor)
        s.floor.vis.light.t(0.7);
      s.vis.light.t(0.4);
      s.vis.active = true;
    }
    playerWalker.clear();
    player.x = currentRoom.walkX * 4 + x;
    player.y = currentRoom.walkY * 4 + y;
    player.z = 0.5; // TODO: floor Z
    Sfx.play('SFX_Teleport_${1 + Std.random(2)}').pos(Std.random(20) - 10, 1, 20);
  }

  public function ending(n:Int, msg:String):Void {
    while (cameraStack.length > 0) unzoom();
    texts.resize(0);
    gameOver = true;
    var msg = '$msg

(ending $n / 4.5)

thank you for playing two tapes
a game by Aurel B%l& and Eido Volta
made for Ludum Dare 47';
    beatWait = true;
    var et = {
      x: 8,
      y: 0,
      msg: Text.split(msg, 240),
      colour: 0xffffff,
      visTarget: null,
      prog: 0,
    };
    var eyt = new Hyst(0, 16, .999);
    anim.push({
      prog: 0,
      len: 300,
      f: _ -> et.y = eyt.tickI(),
      done: () -> {
        et.msg = Text.split(msg + "


click to restart", 240);
        gameOverRestart = true;
      },
      blocking: true,
    });
    texts.push(et);
  }

  public var behold = 0;
  public var bs:Sfx.SfxChannel;

  public function tick(delta:Float):Void {
    if (castle == null) return;

    if (currentRoom.id == "1b") {
      faucet++;
      if (30 + Std.random(1000) < faucet) {
        faucet = 0;
        Sfx.play('SFX_WaterDrop_${1 + Std.random(4)}');
      }
    } else if (currentRoom.id == "1c") {
      faucet++;
      if (300 + Std.random(3000) < faucet) {
        faucet = 0;
        Sfx.play('SFX_Wind_${1 + Std.random(2)}');
      }
    } else faucet = 0;

    if (bs == null) {
      bs = Sfx.play("SFX_Mechanism_6").loop(true).vol(0);
    }
    bs.vol((behold / 800).clamp(0, 1));

    if (!beatWait) {
      VM["2b1/floor"].z = Std.int((1 - behold / 800).clamp(-1, 1) * -20.);
      VM["2b2/floor"].z = Std.int((1 - behold / 800).clamp(-1, 1) * -20.);
      VM["2b1/floor"].alpha.t((behold / 800).clamp(0, 1) * .9);
      VM["2b2/floor"].alpha.t((behold / 800).clamp(0, 1) * .9);
      behold += (playerWalker.current != null ? 3 : -4);
      if (behold < 0) behold = 0;
      if (behold > 1200) {
        ending(3, "watch your step next time");
        playerWalker.clear();
        player.sub[0].alpha.t(0);
        player.sub[1].alpha.t(0);
        player.sub[2].alpha.t(0);
        behold = 1200;
      }
    }
    if (behold > 650) {
      if (Math.random() > 0.96) bs.seek(Math.random() * 4);
      cameraX.value += (Math.random() - .5) * ((behold - 650) / 150);
      cameraY.value += (Math.random() - .5) * ((behold - 650) / 150);
      cameraZ.value += (Math.random() - .5) * ((behold - 650) / 150);
    }

    // sort out UI and mouse
    anyDialogue = (dialogueWakeup != null || choices != null || beatWait);
    var cursor = Cursor.Normal;
    mOverUI = null;
    for (u in uiArr) {
      if (u.active && mouseX >= u.x && mouseX < u.x + u.width && mouseY >= u.y && mouseY < u.y + u.height) {
        mOverUI = u;
        break;
      }
    }
    var prevIx = mOverIx;
    mOverIx = null;
    if (anim.length > 0 && anim[0].blocking) {
      // ...
    } else if (mOverUI != null) {
      mOverIx = mOverUI.ix;
      if ((mOverUI == ui.cancel || mOverUI == ui.goBack) && !anyDialogue
        && mOverVis != null && mOverVis.room == currentRoom && mOverVis.parentIx != null
        && mOverVis.parentIx.detail == cameraStack.length
      ) {
        mOverIx = mOverVis.parentIx;
      }
    } else {
      if (
        !anyDialogue
        && mOverVis != null && mOverVis.room == currentRoom && mOverVis.parentIx != null
        && mOverVis.parentIx.detail == cameraStack.length
      ) {
        mOverIx = mOverVis.parentIx;
      }
    }
    if (prevIx != mOverIx) {
      if (prevIx != null) {
        prevIx.hover = false;
        if (prevIx != mHeldIx) prevIx.tick();
      }
      if (mOverIx != null) {
        mOverIx.hover = true;
        if (mOverIx != mHeldIx) mOverIx.tick();
      }
    }
    if (mHeldIx != null) {
      cursor = mHeldIx.cursor;
      mHeldIx.tick();
    } else if (mOverIx != null) {
      cursor = mOverIx.cursor;
    }

    // update vis states
    if (anim.length > 0) {
      anim[0].f(++anim[0].prog / anim[0].len);
      if (anim[0].prog >= anim[0].len) {
        anim[0].done();
        anim.shift();
      }
    }
    playerWalker.tick();
    castle.root.prerender(0, 0, 0, 0);

    // update camera and state
    if (cameraTarget != null) {
      var pos = cameraTarget.zoomPos();
      cameraX.t(pos.x);
      cameraY.t(pos.y);
      cameraZ.t(pos.z);
    }
    zoomX = cameraZoom.tick() * ZX;
    zoomY = cameraZoom.value * ZY;
    cameraX.tick();
    cameraY.tick();
    cameraZ.tick();
    cameraAngle.tickAngle();

    effectVis.prerender(cameraX.value, cameraY.value, cameraZ.value, -cameraAngle.value);

    ui.cancel.active = cancelWakeup != null;
    ui.cancel.ix.name = cancelText;
    ui.goBack.active = cameraStack.length > 0;
    ui.progressDialogue.active = dialogueWakeup != null;
    if (choices == null) {
      for (c in ui.choices) c.active = false;
    } else {
      for (i in 0...ui.choices.length) {
        ui.choices[i].active = (i < choices.length);
      }
    }
    if (cameraStack.length == 0 && !anyDialogue) {
      ui.turnLeft.active = true;
      ui.turnRight.active = true;
      if (!ui.turnLeft.ix.held && (Main.input.keyboard.held[Key.KeyA] || Main.input.keyboard.held[Key.ArrowLeft])) cameraAngle.d(0.05);
      if (!ui.turnRight.ix.held && (Main.input.keyboard.held[Key.KeyD] || Main.input.keyboard.held[Key.ArrowRight])) cameraAngle.d(-0.05);
    } else {
      ui.turnLeft.active = false;
      ui.turnRight.active = false;
    }

    // render
    //ImDebug.text("current", currentRoom.id);
    //ImDebug.text("2a 2b", '${castle.roomMap["2a"].vis.parentLight} ${castle.roomMap["2b"].vis.parentLight}');

    //if (ImDebug.checkbox("spin")) VM["floor1"].angle += 0.001 * delta;
    //VM["foo"].angle = Math.atan(0.5);
    //VM["foo"].angle = VM["foo"].angle.clipAngle();

    castle.floors[0].vis.active = ImDebug.checkbox("floor1", true);
    castle.floors[1].vis.active = ImDebug.checkbox("floor2", true);
    //castle.floors[2].vis.active = ImDebug.checkbox("floor3", true);

    if (ImDebug.button("cz floor1")) cameraZ.t(0);
    if (ImDebug.button("cz floor2")) cameraZ.t(-24);
    if (ImDebug.button("cz floor3")) cameraZ.t(-48);

    if (ImDebug.button("cx-")) cameraX.d(-16);
    if (ImDebug.button("cx+")) cameraX.d(16);
    if (ImDebug.button("cy-")) cameraY.d(-16);
    if (ImDebug.button("cy+")) cameraY.d(16);

    ImDebug.text("ct", '${cameraX.target} ${cameraY.target} ${cameraAngle.target} ${cameraTarget.id} ${cameraStack.length}');

    // cameraZoom.t(ImDebug.checkbox("zoom out") ? .5 : 1);

    shader.renderStart();

    inline function maybeFlush():Void {
      if (vertexCount > 1024) {
        shader.renderFlush();
        vertexCount = 0;
      }
    }

    shader.flats.U.depthPass.writeI32([1]);
    inline function flatsPass() {
      vertexCount = 0;
      shader.renderStage(surf, shader.flats, stage -> {
        stage.U.cameraPosition.writeF32([
          cameraX.value,
          cameraY.value,
          cameraZ.value
        ]);
        stage.U.cameraZoom.writeF32([zoomX, 1, 2 * cameraZoom.value]);
        stage.U.cameraAngle.writeF32([cameraAngle.value, 1, zoomY * .5]);
        var idx = 1;
        for (vis in Vis.VIS_ARR) {
          vis.visIndex = idx++;
          vis.renderFlats();
          maybeFlush();
        }
      });
    }
    ctx.clearColor(0, 0, 0, 1.0);
    flatsPass();
    mOverVis = null;
    if (mouseX >= 0 && mouseX < W && mouseY >= 0 && mouseY < H) {
      ctx.readPixels(mouseX, H - mouseY - 1, 1, 1, GL.RGBA, GL.UNSIGNED_BYTE, readBuf);
      var idx = ((readBuf[0] + 2) >> 2) + ((readBuf[1] + 2) >> 2) * 64;
      if (idx > 0) {
        mOverVis = Vis.VIS_ARR[idx - 1];
        mouseTargetX = readBuf[2] / 256;
        mouseTargetY = readBuf[3] / 256;
      }
      ImDebug.text("mouse", '$readBuf');
      ImDebug.text("buttons", '${VM['1d/buttons/b0'].visIndex}, ${VM['1d/buttons/b1'].visIndex}, ${VM['1d/buttons/b2'].visIndex}');
    }
    if (!ImDebug.checkbox("show depth buffer")) {
      ctx.clearDepth(-1.0);
      ctx.clearColor(47. / 256., 29. / 256., 37. / 256., 1.0);
      ctx.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
      shader.flats.U.depthPass.writeI32([0]);
      flatsPass();
    }
    vertexCount = 0;
    shader.renderStage(surf, shader.ui, stage -> {
      musicPuzzle.render();
      deck.render();
      // top layer
      for (t in texts) {
        if (t.visTarget != null) {
          var proj = project(t.visTarget.wX, t.visTarget.wY, t.visTarget.wZ);
          t.x = Std.int(proj.x);
          t.y = Std.int(proj.y - t.msg.height - 4);
        }
        ImDebug.text("text width", '${t.msg.width}');
        var x = t.x - (t.msg.width >> 1);
        var y = t.y;
        if (x < 20) x = 20;
        else if (x + t.msg.width >= W - 20) x = W - 20 - t.msg.width;
        if (y < 15) y = 15;
        else if (y + t.msg.height >= H - 15) y = H - 15 - t.msg.height;
        var light = t.prog / 90;
        if (light > 1) light = 1;
        Text.render(x, y, t.msg.text, t.colour, t.prog); //light);
        t.prog++;
      }
      var tt = null;
      if (gameOver) {
        tooltipText = "";
      }
      if (anyDialogue || gameOver) {
        // no tooltip during dialogue
      } else if (anim.length > 0 && anim[0].blocking) {
        tt = "Please wait...";
      } if (mHeldIx != null && mHeldIx.name != null) {
        tt = mHeldIx.name;
      } else if (mOverIx != null && mOverIx.name != null) {
        tt = mOverIx.name;
      } else if (mOverVis != null && mOverVis.name != null) {
        tt = mOverVis.name;
      }
      if (tt != null) tooltipText = tt;
      tooltipPos.t(tt != null ? -16 : 0);
      var ttw = Text.width(tooltipText);
      if (choices != null) {
        var pos = H - choices.length * 12 - 4;
        for (i in 0...choices.length) {
          ui.choices[i].y = pos;
          var active = ui.choices[i] == mOverUI;
          Text.render(active ? 12 : 8, pos, choices[i].msg, active ? 0xa68ba7 : 0x84708f, 1000);
          pos += 12;
        }
      }
      Text.render(W - 8 - ttw, H + tooltipPos.tickI(), tooltipText, 0x57413F, 1000);
      var col = ui.system.sfx.ix.hover ? .9 : 1;
      renderUI(W - 16, 0, getReg('icons-2'), col, col, col);
      if (!Sfx.enabled) renderUI(W - 16, 0, getReg('icons-3'), col, col, col);
      col = ui.system.music.ix.hover ? .9 : 1;
      renderUI(W - 32, 0, getReg('icons-1'), col, col, col);
      if (!Sfx.enabledM) renderUI(W - 32, 0, getReg('icons-3'), col, col, col);
      renderUI(mouseX - 1, mouseY - 1, getReg('cursor-${(cursor:Int)}'));
    });
  }

  public function project(x:Float, y:Float, z:Float):{
    x:Float,
    y:Float
  } {
    var translated = [
      x - cameraX.value,
      y - cameraY.value,
      z - cameraZ.value,
    ];
    var cc = Math.cos(cameraAngle.value);
    var cs = Math.sin(cameraAngle.value);
    var rotated = [
      translated[0] * cc + translated[1] * cs,
      -translated[0] * cs + translated[1] * cc,
      translated[2]
    ];
    return {
      x: Math.round(rotated[0] * zoomX) + WH,
      y: Math.round(
        (rotated[1] * zoomY * .5) // top view
        + (-rotated[2]) * 2 * cameraZoom.value // side view
      ) + HH,
    };
  }

  public inline function indexQuad():Void {
    shader.indexBuffer.writeUI16(vertexCount);
    shader.indexBuffer.writeUI16(vertexCount + 1);
    shader.indexBuffer.writeUI16(vertexCount + 2);
    shader.indexBuffer.writeUI16(vertexCount + 1);
    shader.indexBuffer.writeUI16(vertexCount + 3);
    shader.indexBuffer.writeUI16(vertexCount + 2);
    vertexCount += 4;
  }

  inline function flatsCommon(vis:Vis):Void {
    var st = shader.flats.A;

    st.uv.writeF32(vis.tx);
    st.uv.writeF32(vis.ty);
    st.uv.writeF32(vis.tx + vis.twx);
    st.uv.writeF32(vis.ty + vis.twy);
    st.uv.writeF32(vis.tx + vis.thx);
    st.uv.writeF32(vis.ty + vis.thy);
    st.uv.writeF32(vis.tx + vis.twx + vis.thx);
    st.uv.writeF32(vis.ty + vis.twy + vis.thy);

    var sprite = vis.kind.match(Sprite | RotoSprite(_));
    var vtw = sprite ? vis.w / 2 : 0;
    st.props.writeF32(vis.highlight.value);
    st.props.writeF32(-vtw);
    st.props.writeF32(vis.parentLight);
    st.props.writeF32(vis.alpha.tick());
    st.props.writeF32(vis.highlight.value);
    st.props.writeF32(vtw);
    st.props.writeF32(vis.parentLight);
    st.props.writeF32(vis.alpha.value);
    st.props.writeF32(vis.highlight.value);
    st.props.writeF32(-vtw);
    st.props.writeF32(vis.parentLight);
    st.props.writeF32(vis.alpha.value);
    st.props.writeF32(vis.highlight.value);
    st.props.writeF32(vtw);
    st.props.writeF32(vis.parentLight);
    st.props.writeF32(vis.alpha.value);

    st.index.writeF32(vis.visIndex);
    st.index.writeF32(0);
    st.index.writeF32(0);
    st.index.writeF32(vis.visIndex);
    st.index.writeF32(1);
    st.index.writeF32(0);
    st.index.writeF32(vis.visIndex);
    st.index.writeF32(0);
    st.index.writeF32(1);
    st.index.writeF32(vis.visIndex);
    st.index.writeF32(1);
    st.index.writeF32(1);
  }

  public function renderUI(x:Int, y:Int, reg:Region, ?r:Float = 1, ?g:Float = 1, ?b:Float = 1, ?a:Float = 1):Void {
    inline renderUIRaw(x, y, reg.tx, reg.ty, reg.tw, reg.th, r, g, b, a);
  }

  public function renderUIRaw(x:Int, y:Int, tx:Int, ty:Int, tw:Int, th:Int, r:Float, g:Float, b:Float, a:Float):Void {
    var st = shader.ui.A;

    indexQuad();

    st.position.writeF32(x);
    st.position.writeF32(y);
    st.position.writeF32(x + tw);
    st.position.writeF32(y);
    st.position.writeF32(x);
    st.position.writeF32(y + th);
    st.position.writeF32(x + tw);
    st.position.writeF32(y + th);

    st.uv.writeF32(tx);
    st.uv.writeF32(ty);
    st.uv.writeF32(tx + tw);
    st.uv.writeF32(ty);
    st.uv.writeF32(tx);
    st.uv.writeF32(ty + th);
    st.uv.writeF32(tx + tw);
    st.uv.writeF32(ty + th);

    st.recolour.writeF32(r);
    st.recolour.writeF32(g);
    st.recolour.writeF32(b);
    st.recolour.writeF32(a);
    st.recolour.writeF32(r);
    st.recolour.writeF32(g);
    st.recolour.writeF32(b);
    st.recolour.writeF32(a);
    st.recolour.writeF32(r);
    st.recolour.writeF32(g);
    st.recolour.writeF32(b);
    st.recolour.writeF32(a);
    st.recolour.writeF32(r);
    st.recolour.writeF32(g);
    st.recolour.writeF32(b);
    st.recolour.writeF32(a);
  }

  public function renderFloor(vis:Vis):Void {
    var s = vis.wS * vis.wM;
    var c = vis.wC * vis.wM;
    var st = shader.flats.A;

    indexQuad();

    var xap = [c, -s];
    var yap = [s, c];

    st.position.writeF32(vis.wX);
    st.position.writeF32(vis.wY);
    st.position.writeF32(vis.wZ);
    st.position.writeF32(vis.parentZBias);
    st.position.writeF32(vis.wX + xap[0] * (vis.w - 1));
    st.position.writeF32(vis.wY + xap[1] * (vis.w - 1));
    st.position.writeF32(vis.wZ);
    st.position.writeF32(vis.parentZBias);
    st.position.writeF32(vis.wX + yap[0] * (vis.h - 1));
    st.position.writeF32(vis.wY + yap[1] * (vis.h - 1));
    st.position.writeF32(vis.wZ);
    st.position.writeF32(vis.parentZBias);
    st.position.writeF32(vis.wX + xap[0] * (vis.w - 1) + yap[0] * (vis.h - 1));
    st.position.writeF32(vis.wY + xap[1] * (vis.w - 1) + yap[1] * (vis.h - 1));
    st.position.writeF32(vis.wZ);
    st.position.writeF32(vis.parentZBias);

    flatsCommon(vis);
  }

  public function renderWall(vis:Vis):Void {
    if (!vis.doubleSided && Math.abs(((vis.wA + cameraAngle.value) % Hacks.AF).clipAngle()) >= AQ) return;

    var s = vis.wS * vis.wM;
    var c = vis.wC * vis.wM;
    var st = shader.flats.A;

    indexQuad();

    var xap = [c, -s];
    var h = (vis.h - 1) * vis.wM;
    // var yap = [s, c];

    st.position.writeF32(vis.wX);
    st.position.writeF32(vis.wY);
    st.position.writeF32(vis.wZ + h);
    st.position.writeF32(vis.parentZBias);
    st.position.writeF32(vis.wX + xap[0] * (vis.w - 1));
    st.position.writeF32(vis.wY + xap[1] * (vis.w - 1));
    st.position.writeF32(vis.wZ + h);
    st.position.writeF32(vis.parentZBias);
    st.position.writeF32(vis.wX);
    st.position.writeF32(vis.wY);
    st.position.writeF32(vis.wZ);
    st.position.writeF32(vis.parentZBias);
    st.position.writeF32(vis.wX + xap[0] * (vis.w - 1));
    st.position.writeF32(vis.wY + xap[1] * (vis.w - 1));
    st.position.writeF32(vis.wZ);
    st.position.writeF32(vis.parentZBias);

    flatsCommon(vis);
  }

  public function renderSprite(vis:Vis):Void {
    var st = shader.flats.A;

    indexQuad();

    st.position.writeF32(vis.wX);
    st.position.writeF32(vis.wY);
    st.position.writeF32(vis.wZ + vis.h);
    st.position.writeF32(vis.parentZBias);
    st.position.writeF32(vis.wX);
    st.position.writeF32(vis.wY);
    st.position.writeF32(vis.wZ + vis.h);
    st.position.writeF32(vis.parentZBias);
    st.position.writeF32(vis.wX);
    st.position.writeF32(vis.wY);
    st.position.writeF32(vis.wZ);
    st.position.writeF32(vis.parentZBias);
    st.position.writeF32(vis.wX);
    st.position.writeF32(vis.wY);
    st.position.writeF32(vis.wZ);
    st.position.writeF32(vis.parentZBias);

    flatsCommon(vis);
  }
}
