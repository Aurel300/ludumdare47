package shade;

class StageFlats extends aphic.ShaderStage {
  final W:Float = 300.;
  final H:Float = 240.;
  final WH:Float = 150.;
  final HH:Float = 120.;

  var U:{
    texture:Texture,
    textureSize:Vec2,
    cameraPosition:Vec3, // pos.xyz
    cameraZoom:Vec3, // x, y, z
    cameraAngle:Vec3, // around.x, side.y, top.z
    depthPass:Int,
  };
  var A:{
    position:Vec4, // pos.xyz, zBias.w
    uv:Vec2,
    index:Vec3, // index.x, pos.yz
    props:Vec4, // highlight.x, spriteX.y, light.z, alpha.w
  };
  var V:{
    uv:Vec2,
    index:Vec3,
    props:Vec4,
  };

  function vertex():Vec4 {
    var translated = A.position.xyz - U.cameraPosition;
    var cc = cos(U.cameraAngle.x);
    var cs = sin(U.cameraAngle.x);
    var rotated = [
      translated.x * cc + translated.y * cs,
      -translated.x * cs + translated.y * cc,
      translated.z
    ];
    var projected = [
      roundU(rotated.x * U.cameraZoom.x) + WH,
      roundU(
        (rotated.y * U.cameraAngle.z) * U.cameraZoom.y // top view
        + (-rotated.z * U.cameraAngle.y) * U.cameraZoom.z // side view
      ) + HH,
    ];
    projected.x += A.props.y * U.cameraZoom.x;
    V.uv = A.uv;
    V.index = A.index;
    V.props = A.props;
    return [
      (projected.x - WH) / WH,
      ((H - projected.y) - HH) / HH,
      (translated.z + projected.y + A.position.w) * 0.001,
      1,
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
    if (U.depthPass == 1) {
      return [
        (floor(int(V.index.x % 64.)) + .25) / 64.,
        (floor(int(V.index.x / 64.)) + .25) / 64.,
        V.index.y,
        V.index.z,
      ];
    } else {
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
      /**//* if (sub ==  0) { limit = 5; }
      else if (sub ==  1) { limit = 6; }
      else if (sub ==  2) { limit = 9; }
      else if (sub ==  3) { limit = 10; }
      else if (sub ==  4) { limit = 4; }
      else if (sub ==  5) { limit = 7; }
      else if (sub ==  6) { limit = 8; }
      else if (sub ==  7) { limit = 11; }
      else if (sub ==  8) { limit = 3; }
      else if (sub ==  9) { limit = 2; }
      else if (sub == 10) { limit = 13; }
      else if (sub == 11) { limit = 12; }
      else if (sub == 12) { limit = 0; }
      else if (sub == 13) { limit = 1; }
      else if (sub == 14) { limit = 14; }
      else if (sub == 15) { limit = 15; }
      else {}*/
      var lOff = (limit / 7.5) - 1.;
      var alpha = V.props.w;
      alpha = clamp((alpha * 1.1) - 0.05 + lOff * 0.4, 0, 1);
      if (alpha < 0.5) {
        return;
      }
      var dark = 1 - V.props.z;
      dark = clamp((dark * 1.4) - 0.2 + lOff * 0.1, 0, 1);
      var highlight = V.props.x * .3;
      sample.rgb = [
        sample.r * (1 - highlight - dark) + (191. / 256.) * highlight + (47. / 256.) * dark,
        sample.g * (1 - highlight - dark) + (196. / 256.) * highlight + (29. / 256.) * dark,
        sample.b * (1 - highlight - dark) + (167. / 256.) * highlight + (37. / 256.) * dark,
      ];
      return sample;
    }
  }
}
