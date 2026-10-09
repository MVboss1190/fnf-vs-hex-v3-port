package funkin.util;

import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;

/**
 * Sorts a group by V-Slice's `zIndex` (added to FlxBasic by FlxMacro), keeping the order of equal values.
 */
class ZIndex
{
	public static function sort(group:FlxTypedGroup<FlxBasic>):Void
	{
		var indexed = [for (i => m in group.members) {i: i, m: m}];
		indexed.sort((a, b) ->
		{
			var za:Int = a.m != null ? a.m.zIndex : 0;
			var zb:Int = b.m != null ? b.m.zIndex : 0;
			return za == zb ? a.i - b.i : za - zb;
		});
		for (i => entry in indexed) group.members[i] = entry.m;
	}
}
