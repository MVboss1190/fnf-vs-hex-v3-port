package funkin;

/**
 * VS Hex compatibility: V-Slice's preferences, mapped onto Psych's ClientPrefs.
 * Values Psych doesn't have are kept in the save under `hexPrefs`.
 */
class Preferences
{
	static function extra():Dynamic
	{
		if (FlxG.save.data.hexPrefs == null) FlxG.save.data.hexPrefs = {};
		return FlxG.save.data.hexPrefs;
	}

	static function getExtra<T>(name:String, fallback:T):T
	{
		var v:Dynamic = Reflect.field(extra(), name);
		return v != null ? v : fallback;
	}

	static function setExtra<T>(name:String, value:T):T
	{
		Reflect.setField(extra(), name, value);
		FlxG.save.flush();
		return value;
	}

	static inline function save():Void
		ClientPrefs.saveSettings();

	public static var naughtyness(get, set):Bool;
	static function get_naughtyness():Bool return getExtra('naughtyness', true);
	static function set_naughtyness(v:Bool):Bool return setExtra('naughtyness', v);

	public static var downscroll(get, set):Bool;
	static function get_downscroll():Bool return ClientPrefs.data.downScroll;
	static function set_downscroll(v:Bool):Bool
	{
		ClientPrefs.data.downScroll = v;
		save();
		return v;
	}

	/** Percent, 0 to 100. */
	public static var strumlineBackgroundOpacity(get, set):Int;
	static function get_strumlineBackgroundOpacity():Int return getExtra('strumlineBackgroundOpacity', 0);
	static function set_strumlineBackgroundOpacity(v:Int):Int return setExtra('strumlineBackgroundOpacity', v);

	public static var flashingLights(get, set):Bool;
	static function get_flashingLights():Bool return ClientPrefs.data.flashing;
	static function set_flashingLights(v:Bool):Bool
	{
		ClientPrefs.data.flashing = v;
		save();
		return v;
	}

	public static var unlockedFramerate(get, set):Bool;
	static function get_unlockedFramerate():Bool return getExtra('unlockedFramerate', false);
	static function set_unlockedFramerate(v:Bool):Bool return setExtra('unlockedFramerate', v);

	public static var vsyncMode(get, set):Int;
	static function get_vsyncMode():Int return getExtra('vsyncMode', 0);
	static function set_vsyncMode(v:Int):Int return setExtra('vsyncMode', v);

	public static var framerate(get, set):Int;
	static function get_framerate():Int return ClientPrefs.data.framerate;
	static function set_framerate(v:Int):Int
	{
		ClientPrefs.data.framerate = v;
		if (v > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = v;
			FlxG.drawFramerate = v;
		}
		else
		{
			FlxG.drawFramerate = v;
			FlxG.updateFramerate = v;
		}
		save();
		return v;
	}

	public static var zoomCamera(get, set):Bool;
	static function get_zoomCamera():Bool return ClientPrefs.data.camZooms;
	static function set_zoomCamera(v:Bool):Bool
	{
		ClientPrefs.data.camZooms = v;
		save();
		return v;
	}

	public static var autoPause(get, set):Bool;
	static function get_autoPause():Bool return ClientPrefs.data.autoPause;
	static function set_autoPause(v:Bool):Bool
	{
		ClientPrefs.data.autoPause = v;
		FlxG.autoPause = v;
		save();
		return v;
	}

	public static var autoFullscreen(get, set):Bool;
	static function get_autoFullscreen():Bool return getExtra('autoFullscreen', false);
	static function set_autoFullscreen(v:Bool):Bool return setExtra('autoFullscreen', v);

	public static var shouldHideMouse(get, set):Bool;
	static function get_shouldHideMouse():Bool return getExtra('shouldHideMouse', false);
	static function set_shouldHideMouse(v:Bool):Bool return setExtra('shouldHideMouse', v);
}
