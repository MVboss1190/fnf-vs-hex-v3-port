package funkin.modding;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * Shown instead of the base game's title when VS Hex didn't take over the menus,
 * so a broken install says why instead of silently looking like plain Friday Night Funkin'.
 */
class HexLoadErrorState extends FlxState
{
  override public function create():Void
  {
    super.create();

    var lines:Array<String> = [];
    lines.push('VS Hex failed to start.');
    lines.push('');
    lines.push('Loaded mods: ' + (PolymodHandler.loadedModIds.length > 0 ? PolymodHandler.loadedModIds.join(', ') : 'none'));
    lines.push('Mods folder: ' + PolymodHandler.MOD_FOLDER + ' (cwd ' + #if sys Sys.getCwd() #else '?' #end + ')');
    #if sys
    lines.push('Hex files present: ' + sys.FileSystem.exists(PolymodHandler.MOD_FOLDER + '/hex/_polymod_meta.json'));
    #end
    lines.push('');
    if (PolymodErrorHandler.recentErrors.length > 0)
    {
      lines.push('Errors:');
      for (e in PolymodErrorHandler.recentErrors)
        lines.push('- ' + (e.length > 220 ? e.substr(0, 220) + '...' : e));
    }
    else
      lines.push('No errors were reported.');
    lines.push('');
    lines.push('Please send a screenshot of this screen. Tap / press Enter to continue anyway.');

    var text:FlxText = new FlxText(40, 40, FlxG.width - 80, lines.join('\n'), 18);
    text.color = FlxColor.WHITE;
    add(text);
    trace('[HEX] ' + lines.join(' | '));
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
    var tapped:Bool = #if FLX_TOUCH FlxG.touches.justStarted().length > 0 || #end FlxG.keys.justPressed.ENTER;
    if (tapped) FlxG.switchState(() -> new funkin.ui.title.TitleState());
  }
}
