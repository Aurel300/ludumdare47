package shade;

class StageUI extends aphic.ShaderStage {
  final W:Float = 300.;
  final H:Float = 240.;
  final WH:Float = 150.;
  final HH:Float = 120.;

  var U:{
    texture:Texture,
    textureSize:Vec2,
  };
  var A:{
    position:Vec2,
    uv:Vec2,
    recolour:Vec4, // col.rgb, alpha.w
  };
  var V:{
    uv:Vec2,
    recolour:Vec4,
  };

  function vertex():Vec4 {
    V.uv = A.uv;
    V.recolour = A.recolour;
    return [
      (A.position.x - WH) / WH,
      ((H - A.position.y)  - HH) / HH,
      0.999,
      1
    ];
  }

  function fragment():Vec4 {
    var sample = U.texture.sample(
      (roundU(V.uv.x - 0.5)) / (U.textureSize.x - 1),
      (roundU(V.uv.y - 0.5)) / (U.textureSize.y - 1)
    );
    if (sample.a < 0.5) {
      return;
    }
    var subX = floor(gl_FragCoord.x % 4);
    var subY = floor(gl_FragCoord.y % 4);
    var sub = subX + subY * 4;
    var limit = 0;
    /**/ if (sub ==  0) { limit = 0; }
    else if (sub ==  1) { limit = 12; }
    else if (sub ==  2) { limit = 3; }
    else if (sub ==  3) { limit = 15; }
    else if (sub ==  4) { limit = 8; }
    else if (sub ==  5) { limit = 4; }
    else if (sub ==  6) { limit = 11; }
    else if (sub ==  7) { limit = 7; }
    else if (sub ==  8) { limit = 2; }
    else if (sub ==  9) { limit = 14; }
    else if (sub == 10) { limit = 1; }
    else if (sub == 11) { limit = 13; }
    else if (sub == 12) { limit = 10; }
    else if (sub == 13) { limit = 6; }
    else if (sub == 14) { limit = 9; }
    else if (sub == 15) { limit = 15; }
    else {}
    var lOff = (limit / 7.5) - 1.;
    var alpha = V.recolour.w;
    alpha = clamp((alpha * 1.1) - 0.05 + lOff * 0.4, 0, 1);
    if (alpha < 0.5) {
      return;
    }
    return [
      sample.r * V.recolour.r,
      sample.g * V.recolour.g,
      sample.b * V.recolour.b,
      1
    ];
  }
}
