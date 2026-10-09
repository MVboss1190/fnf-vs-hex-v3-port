package funkin.play;

import funkin.play.song.Song;
import states.PlayState as PsychPlayState;

/**
 * VS Hex compatibility: the bits of V-Slice's PlayState that Hex's pause and game over menus use,
 * forwarded to Psych's PlayState.
 */
class PlayState
{
	public static var instance(get, never):PlayState;

	static var _facade:PlayState = new PlayState();

	static function get_instance():PlayState
		return PsychPlayState.instance != null ? _facade : null;

	function new() {}

	var game(get, never):PsychPlayState;

	inline function get_game():PsychPlayState
		return PsychPlayState.instance;

	/** The Hex song entry being played. */
	public var currentSong(get, set):Song;

	function get_currentSong():Song
		return hex.HexPlay.song;

	function set_currentSong(value:Song):Song
		return hex.HexPlay.song = value;

	public var currentDifficulty(get, set):String;

	function get_currentDifficulty():String
		return hex.HexSong.current != null && hex.HexSong.current.difficulty != null ? hex.HexSong.current.difficulty : hex.HexPlay.difficulty;

	function set_currentDifficulty(value:String):String
		return hex.HexPlay.difficulty = value;

	public var previousDifficulty:String = null;

	public var currentVariation(get, never):String;

	function get_currentVariation():String
		return hex.HexSong.current != null ? hex.HexSong.current.variation : hex.HexPlay.variation;

	public var currentChart(get, never):{variation:String};

	function get_currentChart():{variation:String}
		return {variation: currentVariation};

	public var isPracticeMode(get, set):Bool;

	function get_isPracticeMode():Bool
		return game != null && game.practiceMode;

	function set_isPracticeMode(value:Bool):Bool
	{
		if (game != null)
		{
			game.practiceMode = value;
			PsychPlayState.changedDifficulty = true; // marks the score as not saveable, like Psych does
		}
		return value;
	}

	/**
	 * Setting it restarts the song, with the new difficulty if one was picked.
	 */
	public var needsReset(default, set):Bool = false;

	function set_needsReset(value:Bool):Bool
	{
		if (!value || game == null) return value;
		var diff:String = currentDifficulty;
		var song:Song = currentSong;
		var resetDiff:Bool = previousDifficulty != null && previousDifficulty != diff;
		previousDifficulty = null;

		FlxG.sound.music.volume = 0;
		game.vocals.volume = 0;
		game.paused = true;
		if (resetDiff && song != null)
		{
			var variation:String = song.getDifficulty(diff, currentVariation) != null ? currentVariation : song.getFirstValidVariation(diff);
			hex.HexPlay.start(song, diff, variation, PsychPlayState.isStoryMode, game.practiceMode);
		}
		else
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.resetState();
		}
		return false;
	}
}
