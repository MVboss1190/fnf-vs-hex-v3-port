package funkin.play.song;

import funkin.data.song.SongData.SongMetadata;
import hex.HexAssets;

/**
 * VS Hex compatibility: a Hex song with its variations ("default", "new", "erect"), read from its V-Slice metadata.
 */
class Song
{
	public var id(default, null):String;

	/** Metadata of each variation, the default first. Each gets a `variation` field. */
	var metadata:Array<SongMetadata> = [];

	public function new(id:String)
	{
		this.id = id;
		var base:Dynamic = HexAssets.getJson('gameplay/songs/$id/$id-metadata.json');
		if (base == null) return;
		base.variation = 'default';
		metadata.push(base);

		var variations:Array<String> = base.playData != null ? base.playData.songVariations : null;
		if (variations != null)
			for (v in variations)
			{
				var meta:Dynamic = HexAssets.getJson('gameplay/songs/$id/$id-metadata-$v.json');
				if (meta == null) continue;
				meta.variation = v;
				metadata.push(meta);
			}
	}

	public function isValid():Bool
		return metadata.length > 0;

	public function getRawMetadata():Array<SongMetadata>
		return metadata;

	public function listVariations():Array<String>
		return [for (m in metadata) m.variation];

	function metaFor(variation:String):SongMetadata
	{
		if (variation == null) variation = 'default';
		for (m in metadata)
			if (m.variation == variation) return m;
		return null;
	}

	/**
	 * The difficulty in that variation, or null if it isn't charted there. Without a variation, the first one that has it.
	 */
	public function getDifficulty(?diffId:String, ?variation:String, ?variations:Array<String>):Null<SongDifficulty>
	{
		if (diffId == null) diffId = 'normal';
		var candidates:Array<SongMetadata> = variation != null ? [metaFor(variation)] : metadata;
		for (meta in candidates)
		{
			if (meta == null || meta.playData == null) continue;
			var diffs:Array<String> = meta.playData.difficulties;
			if (diffs != null && diffs.contains(diffId)) return new SongDifficulty(this, meta, diffId);
		}
		return null;
	}

	public function listDifficulties(?variation:String):Array<String>
	{
		var meta:SongMetadata = metaFor(variation);
		return (meta != null && meta.playData != null && meta.playData.difficulties != null) ? meta.playData.difficulties : [];
	}

	public function getFirstValidVariation(?diffId:String, ?possibleVariations:Array<String>):Null<String>
	{
		for (meta in metadata)
		{
			var diffs:Array<String> = meta.playData != null ? meta.playData.difficulties : null;
			if (diffs != null && (diffId == null || diffs.contains(diffId))) return meta.variation;
		}
		return null;
	}

	public function getBaseInstrumentalId(?diffId:String, ?variation:String):String
	{
		var meta:SongMetadata = metaFor(variation);
		if (meta == null || meta.playData == null || meta.playData.characters == null) return '';
		var inst:String = meta.playData.characters.instrumental;
		return inst != null ? inst : '';
	}

	/**
	 * The Psych song folder for a variation: "dunk", "dunk-new", "bit-erect".
	 */
	public function folderFor(?variation:String):String
		return (variation == null || variation == 'default') ? id : '$id-$variation';
}

class SongDifficulty
{
	public var song(default, null):Song;
	public var difficulty(default, null):String;
	public var variation(default, null):String;
	public var songName(default, null):String;
	public var songArtist(default, null):String;
	public var difficultyRating(default, null):Int = 0;
	public var metadata(default, null):SongMetadata;

	public function new(song:Song, meta:SongMetadata, difficulty:String)
	{
		this.song = song;
		this.metadata = meta;
		this.difficulty = difficulty;
		this.variation = meta.variation;
		this.songName = meta.songName;
		this.songArtist = meta.artist;
		var ratings:Dynamic = meta.playData != null ? meta.playData.ratings : null;
		if (ratings != null && Reflect.hasField(ratings, difficulty)) difficultyRating = Reflect.field(ratings, difficulty);
	}
}
