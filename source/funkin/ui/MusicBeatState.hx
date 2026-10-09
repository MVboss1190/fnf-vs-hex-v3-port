package funkin.ui;

import funkin.util.ZIndex;

/**
 * VS Hex compatibility: Hex's menus extend V-Slice's MusicBeatState; here that is Psych's.
 */
class MusicBeatState extends backend.MusicBeatState
{
	var zSorted:Bool = false;

	/** Re-sorts members by their V-Slice zIndex. */
	public function refresh():Void
		ZIndex.sort(cast this);

	override function update(elapsed:Float):Void
	{
		if (!zSorted)
		{
			zSorted = true;
			refresh();
		}
		super.update(elapsed);
	}

	override function destroy():Void
	{
		super.destroy();
	}
}
