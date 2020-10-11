class Text {
  public static function render(x:Int, y:Int, text:String, colour:UInt, prog:Float):Void {
    var ox = x;
    var bold = false;
    var shake = false;
    var falling = false;
    var pos = 0;
    var r = ((colour >> 16) & 0xFF) / 256;
    var g = ((colour >> 8) & 0xFF) / 256;
    var b = (colour & 0xFF) / 256;
    while (pos < text.length && pos < prog * .5) {
      var cc = text.charCodeAt(pos++);
      var adv = 6;
      switch (cc) {
        case "\n".code:
          x = ox;
          y += 12;
          continue;
        case "$".code:
          switch (text.charCodeAt(pos++)) {
            case "b".code: bold = !bold; continue;
            case "s".code: shake = !shake; continue;
            case "m".code: falling = !falling; continue;
            case "$".code: cc = "$".code;
            case _: continue;
          }
        case "1".code: adv = 5;
        case "I".code: adv = 5;
        case "M".code: adv = 7;
        case "T".code if (bold): adv = 5;
        case "V".code: adv = 7;
        case "W".code: adv = 7;
        case "Y".code if (!bold): adv = 7;
        case "f".code: adv = 5;
        case "i".code: adv = 5;
        case "l".code: adv = 5;
        case "m".code: adv = 8;
        case "v".code: adv = 7;
        case "w".code if (bold): adv = 8;
        case "w".code: adv = 7;
        case "x".code: adv = 7;
        case _:
      }
      if (bold) adv++;
      if (bold && cc >= "A".code && cc <= "Z".code) adv++;
      var btx = 16;
      var bty = bold ? 592 : 544;
      var tx = ((cc - 32) % 32) * 10;
      var ty = ((cc - 32) >> 5) * 16;
      R.renderUIRaw(
        x + (shake ? Std.int(Math.random() * 2 - 1) : 0),
        y + (shake ? Std.int(Math.random() * 4 - 2) : 0) + (falling ? Std.int(Hacks.quadInOut(((prog - pos * 3) / 890).clamp(0, 1)) * 300.) : 0),
        btx + tx,
        bty + ty,
        10, 16,
        r, g, b, (((prog * .5) - (pos - 5)) / 5).clamp(0, 1)
      );
      x += adv;
    }
  }

  public static function split(text:String, ?maxW:Int = 180):{
    text:String,
    width:Int,
    height:Int,
  } {
    var ret = [];
    for (l in text.split("\n")) {
      var words = l.split(" ");
      if (words.length == 0) {
        ret.push("");
        continue;
      }
      var line = words.shift();
      var pos = width(line);
      for (word in words) {
        var w = width(' $word');
        if (pos + w <= maxW) {
          line += ' $word';
          pos += w;
        } else {
          ret.push(line);
          line = word;
          pos = w;
        }
      }
      ret.push(line);
    }
    var actualW = 0;
    for (l in ret) {
      var w = width(l);
      if (w > actualW) actualW = w;
    }
    return {
      text: ret.join("\n"),
      width: actualW,
      height: ret.length * 12,
    };
  }

  public static inline function line(base:Int, y:Int):Int {
    return Std.int((y - base) / 12);
  }

  public static function width(text:String):Int {
    var max = 0;
    var x = 0;
    var bold = false;
    var pos = 0;
    while (pos < text.length) {
      var cc = text.charCodeAt(pos++);
      var adv = 6;
      switch (cc) {
        case "\n".code:
          x = 0;
          continue;
        case "$".code:
          switch (text.charCodeAt(pos++)) {
            case "b".code: bold = !bold; continue;
            case "$".code: cc = "$".code;
            case _: continue;
          }
        case "1".code: adv = 5;
        case "I".code: adv = 5;
        case "M".code: adv = 7;
        case "T".code if (bold): adv = 5;
        case "V".code: adv = 7;
        case "W".code: adv = 7;
        case "Y".code if (!bold): adv = 7;
        case "f".code: adv = 5;
        case "i".code: adv = 5;
        case "l".code: adv = 5;
        case "m".code: adv = 8;
        case "v".code: adv = 7;
        case "w".code if (bold): adv = 8;
        case "w".code: adv = 7;
        case "x".code: adv = 7;
        case _:
      }
      if (bold) adv++;
      if (bold && cc >= "A".code && cc <= "Z".code) adv++;
      x += adv;
      if (x > max)
        max = x;
    }
    return max;
  }
}
