package kade.hex.util;

import flixel.FlxG;
import funkin.assets.FunkinAssetCache;

// VS Hex port override of Hex's HexPurge.
// This engine's purgeCache() drops every cached graphic, so purging after the switch (as Hex does)
// pulls the textures out from under the menu that was just created. Purge in between instead:
// once the old state is gone and before the new one creates its sprites.
class HexPurge
{
  public static function next(collect:Bool = true):Void
  {
    FunkinAssetCache.instance.preparePurgeCache();

    FlxG.signals.preStateCreate.addOnce(function(_)
    {
      FunkinAssetCache.instance.purgeCache(collect);
    });
  }
}
