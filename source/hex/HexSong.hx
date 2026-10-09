package hex;

import backend.Song.SwagSong;
import states.editors.content.VSlice;
import openfl.media.Sound;

/**
 * VS Hex's songs in their V-Slice format (`gameplay/songs/<id>/<id>-metadata[-variation].json`
 * and `<id>-chart[-variation].json`), loaded into Psych without converting any files.
 *
 * A Psych song folder name picks the song and its variation: `dunk` is the original Dunk,
 * `dunk-new` its "new" version, `bit-erect` the erect remix.
 */
class HexSong
{
	/** The Hex song being played, or null for a regular Psych song. */
	public static var current:HexSong = null;

	public var id(default, null):String;
	public var variation(default, null):String;
	public var difficulty(default, null):String;
	public var metadata(default, null):Dynamic;
	public var chart(default, null):Dynamic;

	/** V-Slice song events (FocusCamera, ZoomCamera...), handled by HexEvents. */
	public var events(default, null):Array<Dynamic> = [];

	public static inline final DEFAULT_VARIATION:String = 'default';

	function new(id:String, variation:String)
	{
		this.id = id;
		this.variation = variation;
		var suffix:String = variationSuffix();
		metadata = HexAssets.getJson('gameplay/songs/$id/$id-metadata$suffix.json');
		chart = HexAssets.getJson('gameplay/songs/$id/$id-chart$suffix.json');
	}

	inline function variationSuffix():String
		return (variation == null || variation == DEFAULT_VARIATION) ? '' : '-$variation';

	/**
	 * Works out which Hex song (and variation) a Psych song folder name means, or null.
	 */
	public static function resolve(folder:String):{id:String, variation:String}
	{
		if (folder == null) return null;
		folder = Paths.formatToSongPath(folder);
		if (HexAssets.exists('gameplay/songs/$folder/$folder-metadata.json'))
			return {id: folder, variation: DEFAULT_VARIATION};

		var dash:Int = folder.lastIndexOf('-');
		while (dash > 0)
		{
			var base:String = folder.substr(0, dash);
			var variation:String = folder.substr(dash + 1);
			if (HexAssets.exists('gameplay/songs/$base/$base-metadata-$variation.json'))
				return {id: base, variation: variation};
			dash = folder.lastIndexOf('-', dash - 1);
		}
		return null;
	}

	public static function isHexSong(folder:String):Bool
		return resolve(folder) != null;

	public static function get(folder:String):HexSong
	{
		var r = resolve(folder);
		if (r == null) return null;
		var song:HexSong = new HexSong(r.id, r.variation);
		return (song.metadata != null && song.chart != null) ? song : null;
	}

	public function difficulties():Array<String>
	{
		var list:Array<String> = metadata.playData != null ? metadata.playData.difficulties : null;
		return list != null ? list : [];
	}

	/**
	 * Display name of the song, like "Hello World".
	 */
	public function name():String
		return metadata.songName != null ? metadata.songName : id;

	/**
	 * Builds the Psych chart for one difficulty. `diffSuffix` is what Psych puts after the folder name
	 * in a chart file name ('' for Normal, '-hard', '-easy-(carol)'...).
	 */
	public function toPsych(diffSuffix:String):SwagSong
	{
		var wanted:String = diffSuffix.startsWith('-') ? diffSuffix.substr(1) : diffSuffix;
		if (wanted.length == 0) wanted = 'normal';

		var diffs:Array<String> = difficulties();
		difficulty = null;
		for (d in diffs)
			if (Paths.formatToSongPath(d) == wanted) difficulty = d;
		if (difficulty == null) difficulty = diffs.length > 0 ? (diffs.contains('normal') ? 'normal' : diffs[0]) : 'normal';

		// Psych's own V-Slice importer does the note and section conversion. It edits what it is given, so pass fresh copies.
		var suffix:String = variationSuffix();
		var chartCopy:Dynamic = HexAssets.getJson('gameplay/songs/$id/$id-chart$suffix.json');
		var metaCopy:Dynamic = HexAssets.getJson('gameplay/songs/$id/$id-metadata$suffix.json');
		var pack:Dynamic = VSlice.convertToPsych(cast chartCopy, cast metaCopy);
		var song:SwagSong = pack.difficulties.get(difficulty);
		if (song == null) return null;

		song.song = name();
		song.format = 'psych_v1';
		// Camera and other V-Slice events run through HexEvents instead of Psych events.
		song.events = [];
		events = chart.events != null ? chart.events.copy() : [];
		events.sort((a, b) -> a.t < b.t ? -1 : (a.t > b.t ? 1 : 0));

		var noteStyle:String = metadata.playData.noteStyle;
		Reflect.setField(song, 'hexNoteStyle', noteStyle);
		return song;
	}

	/**
	 * The instrumental, honouring the metadata's alternate instrumental.
	 */
	public function inst():Sound
	{
		var instId:String = metadata.playData.characters.instrumental;
		var suffix:String = (instId != null && instId.length > 0) ? '-$instId' : '';
		var sound:Sound = HexAssets.sound('gameplay/songs/$id/Inst$suffix');
		if (sound == null) sound = HexAssets.sound('gameplay/songs/$id/Inst');
		return sound;
	}

	/**
	 * Player or opponent vocals, found the way V-Slice looks for them.
	 */
	public function voices(player:Bool):Sound
	{
		var chars:Dynamic = metadata.playData.characters;
		var list:Array<String> = player ? chars.playerVocals : chars.opponentVocals;
		if (list == null || list.length == 0) list = [player ? chars.player : chars.opponent];

		var suffix:String = variationSuffix();
		for (voiceId in list)
		{
			var sound:Sound = HexAssets.sound('gameplay/songs/$id/Voices-$voiceId$suffix');
			if (sound == null) sound = HexAssets.sound('gameplay/songs/$id/Voices-$voiceId');
			if (sound != null) return sound;
		}
		return player ? HexAssets.sound('gameplay/songs/$id/Voices$suffix') : null;
	}

	/**
	 * Called by Psych's Song.getChart: the chart for `jsonInput` inside song folder `folder`, or null if it isn't Hex's.
	 */
	public static function getChart(jsonInput:String, folder:String):SwagSong
	{
		var song:HexSong = get(folder);
		if (song == null) return null;

		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedInput:String = Paths.formatToSongPath(jsonInput);
		if (formattedInput == 'events') return null; // Hex songs keep their events in the chart.
		var suffix:String = formattedInput.startsWith(formattedFolder) ? formattedInput.substr(formattedFolder.length) : '';

		var swag:SwagSong = song.toPsych(suffix);
		if (swag != null) current = song;
		return swag;
	}
}
