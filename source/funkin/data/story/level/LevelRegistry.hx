package funkin.data.story.level;

import funkin.ui.story.Level;

/**
 * VS Hex compatibility: Hex's story levels.
 */
class LevelRegistry
{
	public static var instance(get, null):LevelRegistry;

	static function get_instance():LevelRegistry
	{
		if (instance == null) instance = new LevelRegistry();
		return instance;
	}

	public static final LEVEL_IDS:Array<String> = ['Week X', 'Week X Encore', 'Weekend X', 'Weekend X Freeplay', 'Event Week', 'Event Week Freeplay'];

	var cache:Map<String, Level> = [];

	function new() {}

	public function listSortedLevelIds():Array<String>
		return [for (id in LEVEL_IDS) if (fetchEntry(id) != null) id];

	public function fetchEntry(id:String):Null<Level>
	{
		if (id == null) return null;
		if (cache.exists(id)) return cache.get(id);
		var data:Dynamic = hex.HexAssets.getJson('ui/story-mode/levels/$id.json');
		if (data == null) return null;
		var level:Level = new Level(id, data);
		cache.set(id, level);
		return level;
	}
}
