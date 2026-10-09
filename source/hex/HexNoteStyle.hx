package hex;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxRect;

/**
 * A V-Slice note style from VS Hex (`gameplay/notestyles/<id>/<id>.json`) used for Psych's notes and strums:
 * note and strum spritesheets, the hold strip, and the countdown.
 */
class HexNoteStyle
{
	/** The note style of the Hex song being played, or null. */
	public static var current:HexNoteStyle = null;

	public static var active(get, never):Bool;

	static function get_active():Bool
		return current != null;

	static final DIRS:Array<String> = ['left', 'down', 'up', 'right'];
	static final PSYCH_COLORS:Array<String> = ['purple', 'blue', 'green', 'red'];

	public var id(default, null):String;
	public var data(default, null):Dynamic;

	var noteFramesCache:FlxAtlasFrames = null;
	var strumFramesCache:FlxAtlasFrames = null;

	public static function load(id:String):HexNoteStyle
	{
		if (id == null) return null;
		var json:Dynamic = HexAssets.getJson('gameplay/notestyles/$id/$id.json');
		if (json == null || json.assets == null) return null;
		var style:HexNoteStyle = new HexNoteStyle(id, json);
		return style.isUsable() ? style : null;
	}

	static var noteOnlyCache:Map<String, HexNoteStyle> = [];

	/** A note style that only needs note sprites (mines and other special note kinds). */
	public static function loadNotesOnly(id:String):HexNoteStyle
	{
		if (id == null) return null;
		if (noteOnlyCache.exists(id)) return noteOnlyCache.get(id);
		var json:Dynamic = HexAssets.getJson('gameplay/notestyles/$id/$id.json');
		var style:HexNoteStyle = null;
		if (json != null && json.assets != null && json.assets.note != null
			&& HexAssets.exists(HexAssets.clean(json.assets.note.assetPath) + '.png'))
			style = new HexNoteStyle(id, json);
		noteOnlyCache.set(id, style);
		return style;
	}

	public static function clearCache():Void
		noteOnlyCache.clear();

	function new(id:String, data:Dynamic)
	{
		this.id = id;
		this.data = data;
	}

	function asset(name:String):Dynamic
		return Reflect.field(data.assets, name);

	function isUsable():Bool
	{
		var note:Dynamic = asset('note');
		var strum:Dynamic = asset('noteStrumline');
		return note != null && strum != null && HexAssets.exists(HexAssets.clean(note.assetPath) + '.png')
			&& HexAssets.exists(HexAssets.clean(strum.assetPath) + '.png');
	}

	public var noteScale(get, never):Float;

	function get_noteScale():Float
	{
		var note:Dynamic = asset('note');
		return (note != null && note.scale != null) ? note.scale : 0.7;
	}

	public var strumScale(get, never):Float;

	function get_strumScale():Float
	{
		var strum:Dynamic = asset('noteStrumline');
		return (strum != null && strum.scale != null) ? strum.scale : noteScale;
	}

	public var holdScale(get, never):Float;

	function get_holdScale():Float
	{
		var hold:Dynamic = asset('holdNote');
		return (hold != null && hold.scale != null) ? hold.scale : noteScale;
	}

	/**
	 * Note frames: the note sheet plus hold frames cut from the hold strip,
	 * named the way Psych's Note looks them up ("purple hold piece", "purple hold end").
	 */
	public function noteFrames():FlxAtlasFrames
	{
		if (noteFramesCache != null && noteFramesCache.parent != null && noteFramesCache.parent.bitmap != null) return noteFramesCache;

		var noteSheet:FlxAtlasFrames = HexAssets.atlas(asset('note').assetPath);
		var frames:FlxAtlasFrames = new FlxAtlasFrames(noteSheet.parent);
		frames.addAtlas(noteSheet, true);

		var hold:Dynamic = asset('holdNote');
		var holdGraphic:FlxGraphic = hold != null ? HexAssets.image(hold.assetPath) : null;
		if (holdGraphic != null)
		{
			var holdFrames:FlxAtlasFrames = new FlxAtlasFrames(holdGraphic);
			var w:Float = holdGraphic.width / 8;
			var h:Float = holdGraphic.height;
			for (dir in 0...4)
			{
				var color:String = PSYCH_COLORS[dir];
				holdFrames.addAtlasFrame(FlxRect.get(w * dir * 2, 0, w, h), FlxPoint.get(w, h), FlxPoint.get(), '$color hold piece0000');
				holdFrames.addAtlasFrame(FlxRect.get(w * (dir * 2 + 1), 0, w, h), FlxPoint.get(w, h), FlxPoint.get(), '$color hold end0000');
			}
			frames.addAtlas(holdFrames, true);
		}

		noteFramesCache = frames;
		return frames;
	}

	public function strumFrames():FlxAtlasFrames
	{
		if (strumFramesCache != null && strumFramesCache.parent != null && strumFramesCache.parent.bitmap != null) return strumFramesCache;
		strumFramesCache = HexAssets.atlas(asset('noteStrumline').assetPath);
		return strumFramesCache;
	}

	/** Prefix of the scrolling note for a direction (0-3). */
	public function notePrefix(dir:Int):String
	{
		var d:Dynamic = Reflect.field(asset('note').data, DIRS[dir % 4]);
		return d != null ? d.prefix : null;
	}

	/** Frame rate of the scrolling note animation (animated note kinds like mines). */
	public function noteFrameRate(dir:Int):Int
	{
		var d:Dynamic = Reflect.field(asset('note').data, DIRS[dir % 4]);
		return (d != null && d.frameRate != null) ? Std.int(d.frameRate) : 24;
	}

	/** Prefix of a strum animation: kind is "Static", "Press" or "Confirm". */
	public function strumPrefix(dir:Int, kind:String):String
	{
		var d:Dynamic = Reflect.field(asset('noteStrumline').data, DIRS[dir % 4] + kind);
		return d != null ? d.prefix : null;
	}

	/** Countdown image for step 1-3 (ready, set, go), or null. */
	public function countdownImage(step:Int):String
	{
		var name:String = ['countdownThree', 'countdownTwo', 'countdownOne', 'countdownGo'][step];
		var a:Dynamic = asset(name);
		return (a != null && a.assetPath != null) ? HexAssets.clean(a.assetPath) : null;
	}

	public function countdownScale(step:Int):Float
	{
		var name:String = ['countdownThree', 'countdownTwo', 'countdownOne', 'countdownGo'][step];
		var a:Dynamic = asset(name);
		return (a != null && a.scale != null) ? a.scale : 1;
	}

	/** Countdown sound for step 0-3 (three, two, one, go), or null. */
	public function countdownSound(step:Int):openfl.media.Sound
	{
		var name:String = ['countdownThree', 'countdownTwo', 'countdownOne', 'countdownGo'][step];
		var a:Dynamic = asset(name);
		if (a == null || a.data == null || a.data.audioPath == null) return null;
		return HexAssets.sound(a.data.audioPath);
	}
}
