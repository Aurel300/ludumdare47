@:structInit
class Region {
  public static var REGIONS:Map<String, Region> = [];

  public static function getReg(id:String):Region {
    var ret = REGIONS[id];
    if (ret == null) {
      Debug.error('no such region: $id');
      throw "!";
    }
    return ret;
  }

  public static function init(data:String):Void {
    var tr:haxe.DynamicAccess<Dynamic> = haxe.Json.parse(data);
    function process(params:String, v:Dynamic):Void {
      var params = params.split(" ");
      var id = params.pop();
      var reg:Region = {
        tx: v.x,
        ty: v.y,
        tw: v.w,
        th: v.h,
        height: 0,
      };
      var xd = reg.tw;
      var yd = reg.th;
      for (p in params) {
        if (p.startsWith("H=")) {
          reg.height = Std.parseInt(p.substr(2));
        } else if (p.startsWith("XD=")) {
          xd = Std.parseInt(p.substr(3));
        } else if (p.startsWith("YD=")) {
          yd = Std.parseInt(p.substr(3));
        } else if (p.startsWith("X=")) {
          for (i in 0...Std.parseInt(p.substr(2))) {
            REGIONS['$id-$i'] = ({
              tx: reg.tx + xd * i,
              ty: reg.ty,
              tw: reg.tw,
              th: reg.th,
              height: reg.height,
            }:Region);
          }
        } else if (p.startsWith("Y=")) {
          for (i in 0...Std.parseInt(p.substr(2))) {
            REGIONS['$id-$i'] = ({
              tx: reg.tx,
              ty: reg.ty + yd * i,
              tw: reg.tw,
              th: reg.th,
              height: reg.height,
            }:Region);
          }
        } else {
          Debug.error('unknown param: $p');
        }
      }
      REGIONS[id] = reg;
    }
    for (k => v in tr) process(k, v);
  }

  public var tx:Int;
  public var ty:Int;
  public var tw:Int;
  public var th:Int;
  public var height:Int;
}
