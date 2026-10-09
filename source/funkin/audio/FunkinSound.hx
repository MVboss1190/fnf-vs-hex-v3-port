package funkin.audio;

import flixel.sound.FlxSound;

typedef PlayMusicParams =
{
	@:optional var startingVolume:Float;
	@:optional var overrideExisting:Bool;
	@:optional var restartTrack:Bool;
	@:optional var loop:Bool;
	@:optional var persist:Bool;
	@:optional var mapTimeChanges:Bool;
	@:optional var suffix:String;
	@:optional var pathsFunction:funkin.Paths.PathsFunction;
	@:optional var partialParams:Dynamic;
	@:optional var onLoad:Void->Void;
}

/**
 * VS Hex compatibility: V-Slice's `FunkinSound` as a plain FlxSound with its static helpers.
 */
class FunkinSound extends FlxSound
{
	/** The music path last started with playMusic, so asking for the same track again doesn't restart it. */
	static var currentMusicPath:String = null;

	public static function playOnce(path:String, volume:Float = 1.0, ?onComplete:Void->Void, ?onLoad:Void->Void):FlxSound
	{
		if (path == null || !openfl.utils.Assets.exists(path)) return null;
		var snd:FlxSound = FlxG.sound.play(path, volume, false, null, true, onComplete);
		if (onLoad != null) onLoad();
		return snd;
	}

	public static function load(path:String, volume:Float = 1.0, looped:Bool = false, autoDestroy:Bool = false, autoPlay:Bool = false,
			?onComplete:Void->Void, ?onLoad:Void->Void):FunkinSound
	{
		var snd:FunkinSound = new FunkinSound();
		if (path != null && openfl.utils.Assets.exists(path)) snd.loadEmbedded(path, looped, autoDestroy, onComplete);
		snd.volume = volume;
		FlxG.sound.list.add(snd);
		if (onLoad != null) onLoad();
		if (autoPlay) snd.play();
		return snd;
	}

	public static function loadPartial(path:String, start:Float = 0, end:Float = 1, volume:Float = 1.0, looped:Bool = false, autoDestroy:Bool = false,
			autoPlay:Bool = true, ?onComplete:Void->Void, ?onLoad:Void->Void):lime.app.Promise<FunkinSound>
	{
		var promise:lime.app.Promise<FunkinSound> = new lime.app.Promise<FunkinSound>();
		var snd:FunkinSound = load(path, volume, looped, autoDestroy, autoPlay, onComplete, onLoad);
		promise.complete(snd);
		return promise;
	}

	/**
	 * Plays a music track. Hex gives either a full path ("ui/hex/music/title-theme/title-theme")
	 * or a song id, in which case the song's instrumental is used for the preview.
	 */
	public static function playMusic(key:String, ?params:PlayMusicParams):Bool
	{
		if (params == null) params = {};
		var path:String = params.pathsFunction == INST ? null : funkin.Paths.music(key);
		if (path == null || !openfl.utils.Assets.exists(path))
		{
			var suffix:String = params.suffix != null ? params.suffix : '';
			if (suffix.length > 0 && !suffix.startsWith('-')) suffix = '-$suffix';
			var inst:String = hex.HexAssets.soundPath('gameplay/songs/$key/Inst$suffix');
			if (inst == null) inst = hex.HexAssets.soundPath('gameplay/songs/$key/Inst');
			if (inst == null) return false;
			path = inst;
		}

		var overrideExisting:Bool = params.overrideExisting == true;
		if (!overrideExisting && FlxG.sound.music != null && FlxG.sound.music.playing && currentMusicPath != null) return false;
		if (FlxG.sound.music != null && FlxG.sound.music.playing && currentMusicPath == path && params.restartTrack != true) return false;

		FlxG.sound.playMusic(path, params.startingVolume != null ? params.startingVolume : 1.0, params.loop != false);
		currentMusicPath = path;
		if (FlxG.sound.music != null) FlxG.sound.music.persist = params.persist == true;
		if (params.onLoad != null) params.onLoad();
		return true;
	}
}
