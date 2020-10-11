package shade;

class Shader extends aphic.Shader {
  public var flats:StageFlats;
  public var ui:StageUI;

  public function new() {
    super([
      flats = new StageFlats(),
      ui = new StageUI(),
    ]);
  }
}
