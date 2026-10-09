package funkin.util;

import flixel.FlxG;

/**
 * Performance switches applied at draw time to every camera (see `FlxMacro.buildFlxCamera`).
 * Kept as plain static booleans so the per-draw check costs nothing; `Preferences` keeps them in sync.
 */
class RenderOptions
{
  /** When false, sprite shaders and camera/game filters are skipped. */
  public static var shaders:Bool = true;

  /** When false, every sprite is drawn without smoothing. */
  public static var antialiasing:Bool = true;

  static var hooked:Bool = false;

  public static function apply(shadersOn:Bool, antialiasingOn:Bool):Void
  {
    shaders = shadersOn;
    antialiasing = antialiasingOn;
    if (!hooked)
    {
      hooked = true;
      FlxG.signals.preDraw.add(syncFilters);
    }
    syncFilters();
  }

  static function syncFilters():Void
  {
    if (FlxG.game != null) FlxG.game.filtersEnabled = shaders;
    if (FlxG.cameras == null) return;
    for (camera in FlxG.cameras.list)
      if (camera != null) camera.filtersEnabled = shaders;
  }
}
