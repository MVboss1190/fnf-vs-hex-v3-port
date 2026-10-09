package funkin.play;

/**
 * VS Hex compatibility: what is being played (story campaign or freeplay song).
 */
class PlayStatePlaylist
{
	public static var isStoryMode:Bool = false;
	public static var playlistSongIds:Array<String> = [];
	public static var campaignScore:Int = 0;
	public static var campaignTitle:String = '';
	public static var campaignId:String = '';
	public static var campaignDifficulty:String = 'normal';
	/** The variation the campaign is played in ("new" for Week X / Weekend X with the new vocals). */
	public static var campaignVariation:String = 'default';

	public static function reset():Void
	{
		isStoryMode = false;
		playlistSongIds = [];
		campaignScore = 0;
		campaignTitle = '';
		campaignId = '';
		campaignDifficulty = 'normal';
		campaignVariation = 'default';
	}
}
