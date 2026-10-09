package funkin.save;

import funkin.play.scoring.Scoring;
import funkin.play.scoring.Scoring.ScoringRank;

typedef SaveScoreTallyData =
{
	var sick:Int;
	var good:Int;
	var bad:Int;
	var shit:Int;
	var missed:Int;
	var combo:Int;
	var maxCombo:Int;
	var totalNotesHit:Int;
	var totalNotes:Int;
}

typedef SaveScoreData =
{
	var score:Int;
	var tallies:SaveScoreTallyData;
}

/**
 * VS Hex compatibility: the parts of V-Slice's save data Hex uses (scores, ranks and Hex's own options),
 * stored in Psych's save file.
 */
class Save
{
	public static var instance(get, null):Save;

	static function get_instance():Save
	{
		if (instance == null) instance = new Save();
		return instance;
	}

	function new() {}

	static function data():Dynamic
	{
		if (FlxG.save.data.hexScores == null) FlxG.save.data.hexScores = {};
		if (FlxG.save.data.hexLevelScores == null) FlxG.save.data.hexLevelScores = {};
		if (FlxG.save.data.hexModOptions == null) FlxG.save.data.hexModOptions = {};
		return FlxG.save.data;
	}

	static inline function songKey(songId:String, difficulty:String, ?variation:String):String
	{
		var v:String = (variation == null || variation.length == 0) ? 'default' : variation;
		return '$songId:$v:$difficulty';
	}

	public function getSongScore(songId:String, difficulty:String, ?variation:String):Null<SaveScoreData>
		return Reflect.field(data().hexScores, songKey(songId, difficulty, variation));

	public function getSongRank(songId:String, difficulty:String, ?variation:String):Null<ScoringRank>
		return Scoring.calculateRank(getSongScore(songId, difficulty, variation));

	/**
	 * Keeps the best score, like V-Slice. Returns true when it was a new best.
	 */
	public function setSongScore(songId:String, difficulty:String, variation:String, score:SaveScoreData):Bool
	{
		var key:String = songKey(songId, difficulty, variation);
		var previous:SaveScoreData = Reflect.field(data().hexScores, key);
		if (previous != null && previous.score >= score.score) return false;
		Reflect.setField(data().hexScores, key, score);
		flush();
		return true;
	}

	public function getLevelScore(levelId:String, difficulty:String):Null<SaveScoreData>
		return Reflect.field(data().hexLevelScores, '$levelId:$difficulty');

	public function setLevelScore(levelId:String, difficulty:String, score:SaveScoreData):Void
	{
		var key:String = '$levelId:$difficulty';
		var previous:SaveScoreData = Reflect.field(data().hexLevelScores, key);
		if (previous != null && previous.score >= score.score) return;
		Reflect.setField(data().hexLevelScores, key, score);
		flush();
	}

	public function getModOptions(modId:String):Dynamic
	{
		var bag:Dynamic = Reflect.field(data().hexModOptions, modId);
		if (bag == null)
		{
			bag = {};
			Reflect.setField(data().hexModOptions, modId, bag);
		}
		return bag;
	}

	public function setModOptions(modId:String, options:Dynamic):Void
	{
		Reflect.setField(data().hexModOptions, modId, options);
		flush();
	}

	public function flush():Void
		FlxG.save.flush();
}
