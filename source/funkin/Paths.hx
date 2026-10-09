package funkin;

/**
 * VS Hex compatibility: V-Slice's `funkin.Paths` for the code ported from Hex's menus.
 * Hex passes paths from the mod's root ("ui/hex/main-menu/bg"), which live under `assets/hex/`.
 */
class Paths
{
	static function resolve(key:String, ext:String):String
	{
		key = hex.HexAssets.clean(key);
		var hexPath:String = hex.HexAssets.ROOT + key + ext;
		if (openfl.utils.Assets.exists(hexPath)) return hexPath;
		return 'assets/' + key + ext;
	}

	public static function image(key:String, ?library:String):String
		return resolve(key, '.png');

	public static function xml(key:String, ?library:String):String
		return resolve(key, '.xml');

	public static function txt(key:String, ?library:String):String
		return resolve(key, '.txt');

	public static function json(key:String, ?library:String):String
		return resolve(key, '.json');

	public static function frag(key:String, ?library:String):String
		return resolve(key, '.frag');

	public static function vert(key:String, ?library:String):String
		return resolve(key, '.vert');

	public static function sound(key:String, ?library:String):String
		return audio(key);

	public static function music(key:String, ?library:String):String
		return audio(key);

	public static function videos(key:String, ?library:String):String
		return resolve(key, key.endsWith('.mp4') ? '' : '.mp4');

	public static function font(key:String, ?ext:String = 'ttf'):String
	{
		var file:String = key.contains('.') ? key : '$key.$ext';
		var hexPath:String = hex.HexAssets.ROOT + file;
		if (openfl.utils.Assets.exists(hexPath)) return hexPath;
		return backend.Paths.font(file);
	}

	static function audio(key:String):String
	{
		var found:String = hex.HexAssets.soundPath(key);
		return found != null ? found : resolve(key, '.ogg');
	}

	public static function getSparrowAtlas(key:String, ?library:String):flixel.graphics.frames.FlxAtlasFrames
		return hex.HexAssets.atlas(key);
}

enum PathsFunction
{
	MUSIC;
	INST;
	VOICES;
	SOUND;
}
