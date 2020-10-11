class UI {
  public var active:Bool = true;
  public var x:Int;
  public var y:Int;
  public var width:Int;
  public var height:Int;
  public var ix:Interactible;

  public function new(x:Int, y:Int, width:Int, height:Int, ix:Interactible) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.ix = ix;
  }
}
