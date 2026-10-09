package funkin.data.song;

import funkin.play.song.Song;

/**
 * VS Hex compatibility: looks up Hex's songs by id.
 */
class SongRegistry
{
	public static var instance(get, null):SongRegistry;

	static function get_instance():SongRegistry
	{
		if (instance == null) instance = new SongRegistry();
		return instance;
	}

	var cache:Map<String, Song> = [];

	function new() {}

	public function fetchEntry(id:String, ?params:Dynamic):Null<Song>
	{
		if (id == null) return null;
		if (cache.exists(id)) return cache.get(id);
		var song:Song = new Song(id);
		if (!song.isValid()) return null;
		cache.set(id, song);
		return song;
	}

	public function hasEntry(id:String):Bool
		return fetchEntry(id) != null;
}
