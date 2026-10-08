package kade.hex.notefield;

/**
 * Stand-in for the notefield host from Kade's unreleased modchart-engine.
 * Without that engine there is no notefield to hand HUD parts to, so offers are ignored.
 */
class Host
{
  public static function offer(what:Dynamic):Void {}

  public static function withdraw(what:Dynamic):Void {}
}
