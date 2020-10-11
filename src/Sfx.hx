typedef SfxChannel = {
  stop:()->SfxChannel,
  fadeIn:(len:Int)->SfxChannel,
  fadeOut:(len:Int)->SfxChannel,
  seek:(pos:Float)->SfxChannel,
  vol:(vol:Float)->SfxChannel,
  pos:(x:Float, y:Float, z:Float)->SfxChannel,
  loop:(_:Bool)->SfxChannel,
};

class Sfx {
  public static var rng = new Chance(0xDEAFF00D);
  public static var enabled:Bool = true;
  public static var enabledM:Bool = true;

  public static function toggle():Void {
    enabled = !enabled;
    if (!enabled) {
      for (id => asset in Asset.ids) {
        if (id.endsWith(".mp3") && id != "Music_Background.mp3") {
          Asset.ids[id].sound.stop();
        }
      }
    }
  }

  public static function toggleM():Void {
    #if ENABLE_SOUND
    enabledM = !enabledM;
    Asset.ids["Music_Background.mp3"].sound.mute(!enabledM);
    #end
  }

  public static function speak():Void {
    play([
      "SFX_DeepMumble_1",
      "SFX_DeepMumble_2",
      "SFX_DeepMumble_3",
      "SFX_Mumble_1",
      "SFX_Mumble_2",
      "SFX_Mumble_3",
      "SFX_Mumble_4",
      "SFX_Mumble_5",
      "SFX_Mumble_6",
      "SFX_Mumble_7",
      "SFX_Mumble_8",
    ][Std.random(11)]);
  }

  public static function init():Void {
    #if ENABLE_SOUND
    Asset.ids["SFX_Step_1.mp3"].sound.volume(.3);
    Asset.ids["SFX_Step_2.mp3"].sound.volume(.3);
    Asset.ids["SFX_WaterDrop_1.mp3"].sound.volume(.3);
    Asset.ids["SFX_WaterDrop_2.mp3"].sound.volume(.3);
    Asset.ids["SFX_WaterDrop_3.mp3"].sound.volume(.3);
    Asset.ids["SFX_WaterDrop_4.mp3"].sound.volume(.3);
    Asset.ids["Music_Background.mp3"].sound.play();
    Asset.ids["Music_Background.mp3"].sound.loop(true);
    Asset.ids["Music_Background.mp3"].sound.volume(.9);
    #end
  }

  static var nullSound:SfxChannel = {
    stop: () -> nullSound,
    fadeIn: _ -> nullSound,
    fadeOut: _ -> nullSound,
    seek: _ -> nullSound,
    vol: _ -> nullSound,
    pos: (_, _, _) -> nullSound,
    loop: _ -> nullSound,
  };

  public static function play(id:String, ?varyPitch:Float = 0.2):SfxChannel {
    #if ENABLE_SOUND
    if (!enabled)
      return nullSound;
    var sound = Asset.ids[id + ".mp3"].sound;
    var channel = sound.play();
    if (varyPitch > 0)
      sound.rate(rng.rangeF(1.0 - varyPitch, 1.0 + varyPitch), channel);
    var ch:SfxChannel = null;
    return ch = {
      stop: () -> { sound.stop(channel); ch; },
      fadeIn: (len:Int) -> { sound.fade(0., 1., len, channel); ch; },
      fadeOut: (len:Int) -> { sound.fade(1., 0., len, channel); ch; },
      seek: (pos:Float) -> { sound.seek(pos, channel); ch; },
      vol: (vol:Float) -> { sound.volume(vol, channel); ch; },
      pos: (x:Float, y:Float, z:Float) -> { sound.pos(x, y, z, channel); ch; },
      loop: (loop:Bool) -> { sound.loop(loop, channel); ch; },
    };
    #else
    return nullSound;
    #end
  }
}
