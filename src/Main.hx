class Main {
  // assets
  public static var aPng:Asset;
  #if ENABLE_SOUND
  public static var aWav:Asset;
  #end

  public static var input:Input;
  public static var ren:Ren;

  public static function main():Void Glewb.initSignal.on(_ -> {
    var canvas = document.querySelector("canvas");
    Glewb.initWebGL(cast canvas);
    #if ITCHIO
    js.Syntax.code("window.addEventListener('resize', {0}, {passive:true})", () -> {
      var vw:Int = js.Browser.window.innerWidth;
      var vh:Int = js.Browser.window.innerHeight;
      var aw:Int = vw;
      var ah:Int = vh;
      var ml:Int = 0;
      var mt:Int = 0;
      if (vw >= vh) { aw = Std.int((vh / 4) * 5); ml = Std.int((vw - aw) / 2); }
      else { ah = Std.int((vw / 5) * 4); mt = Std.int((vh - ah) / 2); }
      ren.canvasWidth = aw;
      ren.canvasHeight = ah;
      canvas.style.width = '${aw}px';
      canvas.style.height = '${ah}px';
      canvas.style.margin = '${mt}px 0 0 ${ml}px';
    });
    #end
    input = new Input(canvas, canvas);
    var preloader = new Preloader([
      aPng = Asset.load(null, "png.glw"),
      #if ENABLE_SOUND
      aWav = Asset.load(null, "wav.glw"),
      #end
    ]);
    /*
    var once = true;
    preloader.loadSignal.on(_ -> {
      if (once) {
        once = false;
      }
    });*/
    #if ENABLE_SOUND
    aWav.loadSignal.on(_ -> {
      Sfx.init();
    });
    #end
    Glewb.rateCapped(delta -> {
      if (preloader.allLoaded) {
        if (!ImDebug.checkbox("pause"))
          ren.tick(delta);
      } else {
        preloader.tick();
        document.querySelector("#tn-progress-1").style.width = preloader.progressPC;
      }
    });
    preloader.loadSignal.on(_ -> {
      document.querySelector("#tn-preloader").className = "done";
      document.querySelector("#tn-progress-1").style.width = "100%";
      ren = new Ren(cast canvas);
      ren.updateAssets();
      /*
      Asset.ids["game.png"].loadSignal.on(_ -> {
        if (ren != null) 
      });*/
    });
  });
}
