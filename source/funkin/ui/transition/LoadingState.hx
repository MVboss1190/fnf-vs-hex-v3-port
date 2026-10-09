package funkin.ui.transition;

import funkin.play.PlayStatePlaylist;
import funkin.play.song.Song;

typedef PlayStateParams =
{
	var targetSong:Song;
	@:optional var targetDifficulty:String;
	@:optional var targetVariation:String;
	@:optional var targetInstrumental:String;
	@:optional var practiceMode:Bool;
	@:optional var minimalMode:Bool;
	@:optional var startTimestamp:Float;
}

/**
 * VS Hex compatibility: starts a Hex song in Psych's PlayState.
 */
class LoadingState
{
	public static function loadPlayState(params:PlayStateParams, shouldStopMusic:Bool = false, asSubState:Bool = false, ?onConstruct:Dynamic):Void
	{
		var song:Song = params.targetSong;
		if (song == null) return;

		var diffId:String = params.targetDifficulty != null ? params.targetDifficulty : 'normal';
		var variation:String = params.targetVariation;
		if (variation == null || song.getDifficulty(diffId, variation) == null) variation = song.getFirstValidVariation(diffId);
		if (variation == null) variation = 'default';

		hex.HexPlay.start(song, diffId, variation, PlayStatePlaylist.isStoryMode, params.practiceMode == true);
	}
}
