package hex;

import backend.Song as PsychSong;
import funkin.play.PlayStatePlaylist;
import funkin.play.song.Song;
import funkin.save.Save;
import states.LoadingState as PsychLoadingState;
import states.PlayState;

/**
 * Starting Hex songs from Hex's menus, and what happens when they end.
 */
class HexPlay
{
	/** The Hex song entry and difficulty id being played, for scores and the menus. */
	public static var song:Song = null;
	public static var difficulty:String = 'normal';
	public static var variation:String = 'default';

	public static function start(target:Song, diffId:String, targetVariation:String, story:Bool, practice:Bool):Void
	{
		song = target;
		difficulty = diffId;
		variation = targetVariation;

		var folder:String = target.folderFor(targetVariation);
		var diffs:Array<String> = target.listDifficulties(targetVariation);
		if (diffs.length == 0) diffs = [diffId];

		Difficulty.list = [for (d in diffs) displayDifficulty(d)];
		PlayState.storyDifficulty = Std.int(Math.max(0, diffs.indexOf(diffId)));
		PlayState.isStoryMode = story;
		PlayState.changedDifficulty = false;
		PlayState.chartingMode = false;

		if (story)
		{
			PlayState.storyPlaylist = [folder];
			for (id in PlayStatePlaylist.playlistSongIds)
			{
				var next:Song = funkin.data.song.SongRegistry.instance.fetchEntry(id);
				if (next == null) continue;
				var v:String = next.getDifficulty(diffId, targetVariation) != null ? targetVariation : 'default';
				PlayState.storyPlaylist.push(next.folderFor(v));
			}
			PlayState.campaignScore = 0;
			PlayState.campaignMisses = 0;
		}

		ClientPrefs.data.gameplaySettings.set('practice', practice);

		PsychSong.loadFromJson(folder + Difficulty.getFilePath(), folder);
		PsychLoadingState.loadAndSwitchState(new PlayState(), true);
	}

	public static function displayDifficulty(id:String):String
	{
		if (id == null || id.length == 0) return id;
		return id.charAt(0).toUpperCase() + id.substr(1);
	}

	/**
	 * Saves the song's score in Hex's format, called from PlayState.endSong.
	 */
	public static function recordScore(game:PlayState):Void
	{
		var current:HexSong = HexSong.current;
		if (current == null || game.practiceMode || game.cpuControlled) return;

		var diff:String = current.difficulty != null ? current.difficulty : difficulty;
		var sicks:Int = 0, goods:Int = 0, bads:Int = 0, shits:Int = 0;
		for (rating in game.ratingsData)
		{
			switch (rating.name)
			{
				case 'sick': sicks = rating.hits;
				case 'good': goods = rating.hits;
				case 'bad': bads = rating.hits;
				case 'shit': shits = rating.hits;
			}
		}
		var hit:Int = sicks + goods + bads + shits;
		var data:SaveScoreData = {
			score: game.songScore,
			tallies: {
				sick: sicks,
				good: goods,
				bad: bads,
				shit: shits,
				missed: game.songMisses,
				combo: game.combo,
				maxCombo: game.combo,
				totalNotesHit: hit,
				totalNotes: Std.int(Math.max(hit + game.songMisses, 1))
			}
		};
		Save.instance.setSongScore(current.id, diff, current.variation, data);

		if (PlayState.isStoryMode)
		{
			PlayStatePlaylist.campaignScore += game.songScore;
			if (PlayState.storyPlaylist.length <= 1)
				Save.instance.setLevelScore(PlayStatePlaylist.campaignId, PlayStatePlaylist.campaignDifficulty, {score: PlayStatePlaylist.campaignScore, tallies: data.tallies});
		}
	}

	/** Back to Hex's menus once a song or campaign is over. */
	public static function exitToMenu(story:Bool):Void
	{
		FlxG.sound.music.stop();
		if (story) MusicBeatState.switchState(new kade.hex.states.HexStoryMenu());
		else MusicBeatState.switchState(new kade.hex.states.HexFreeplay());
	}
}
