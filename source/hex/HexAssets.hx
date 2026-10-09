package hex;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Json;
import openfl.display.BitmapData;
import openfl.utils.Assets as OpenFlAssets;

/**
 * Access to VS Hex's own files, which ship untouched under `assets/hex/` (see Project.xml).
 * Paths are the ones the mod itself uses, e.g. `gameplay/characters/hex/hex` (no extension for images).
 *
 * They are always read through OpenFL so on mobile they come straight from the APK.
 */
class HexAssets
{
	public static inline final ROOT:String = 'assets/hex/';

	/**
	 * Some V-Slice paths point at a library (`shared:characters/BOYFRIEND`); the library doesn't matter here.
	 */
	public static function clean(path:String):String
	{
		if (path == null) return '';
		var colon:Int = path.indexOf(':');
		if (colon >= 0) path = path.substr(colon + 1);
		return path;
	}

	public static inline function path(file:String):String
		return ROOT + clean(file);

	public static function exists(file:String):Bool
		return OpenFlAssets.exists(path(file));

	public static function getText(file:String):String
	{
		var full:String = path(file);
		return OpenFlAssets.exists(full) ? OpenFlAssets.getText(full) : null;
	}

	public static function getJson(file:String):Dynamic
	{
		var text:String = getText(file);
		if (text == null) return null;
		try
		{
			return Json.parse(text);
		}
		catch (e:Dynamic)
		{
			trace('[HEX] Could not parse $file: $e');
			return null;
		}
	}

	/**
	 * Whether an image (`.png`) exists, either in Hex's files or Psych's `images/` folder.
	 */
	public static function imageExists(key:String):Bool
	{
		key = clean(key);
		return exists('$key.png') || Paths.fileExists('images/$key.png', IMAGE);
	}

	/**
	 * Loads an image by its Hex path, falling back to Psych's `images/` folder (used for bf and gf).
	 * Goes through Psych's cache so "GPU Caching" and memory clearing work the same as for Psych's own images.
	 */
	public static function image(key:String, ?allowGPU:Bool = true):FlxGraphic
	{
		key = clean(key);
		var full:String = path('$key.png');
		if (!OpenFlAssets.exists(full)) return Paths.image(key, null, allowGPU);

		if (Paths.currentTrackedAssets.exists(full))
		{
			Paths.localTrackedAssets.push(full);
			return Paths.currentTrackedAssets.get(full);
		}

		var bitmap:BitmapData = OpenFlAssets.getBitmapData(full, false);
		if (bitmap == null) return null;
		return Paths.cacheBitmap(full, null, bitmap, allowGPU);
	}

	/**
	 * Sparrow (XML) or Packer (TXT) spritesheet by Hex path, with Psych's `images/` folder as a fallback.
	 */
	public static function atlas(key:String, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		key = clean(key);
		if (!exists('$key.png')) return Paths.getAtlas(key, null, allowGPU);

		var graphic:FlxGraphic = image(key, allowGPU);
		if (graphic == null) return null;

		var xml:String = getText('$key.xml');
		if (xml != null) return FlxAtlasFrames.fromSparrow(graphic, xml);

		var txt:String = getText('$key.txt');
		if (txt != null) return FlxAtlasFrames.fromSpriteSheetPacker(graphic, txt);

		return null;
	}

	/**
	 * Several spritesheets merged into one set of frames, like V-Slice's "multisparrow" characters.
	 */
	public static function multiAtlas(keys:Array<String>, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var parent:FlxAtlasFrames = null;
		for (key in keys)
		{
			var frames:FlxAtlasFrames = atlas(key, allowGPU);
			if (frames == null) continue;
			if (parent == null)
			{
				parent = new FlxAtlasFrames(frames.parent);
				parent.addAtlas(frames, true);
			}
			else parent.addAtlas(frames, true);
		}
		return parent;
	}

	#if flxanimate
	/**
	 * Loads an Adobe Animate texture atlas folder (Animation.json + spritemap1.json/png).
	 */
	public static function loadAnimateAtlas(spr:FlxAnimate, folder:String):Bool
	{
		folder = clean(folder);
		if (!exists('$folder/Animation.json')) return false;

		var spriteJson:String = null;
		var graphic:FlxGraphic = null;
		for (i in 0...10)
		{
			var st:String = i == 0 ? '' : '$i';
			spriteJson = getText('$folder/spritemap$st.json');
			if (spriteJson != null)
			{
				graphic = image('$folder/spritemap$st');
				break;
			}
		}
		if (spriteJson == null || graphic == null) return false;

		spr.loadAtlasEx(graphic, spriteJson, getText('$folder/Animation.json'));
		return true;
	}
	#end

	public static function sound(key:String):openfl.media.Sound
	{
		key = clean(key);
		for (ext in ['ogg', 'mp3', 'wav'])
		{
			var full:String = path('$key.$ext');
			if (OpenFlAssets.exists(full)) return OpenFlAssets.getSound(full);
		}
		return null;
	}

	/**
	 * Path to pass to FlxG.sound.play / playMusic, or null if the file is missing.
	 */
	public static function soundPath(key:String):String
	{
		key = clean(key);
		for (ext in ['ogg', 'mp3', 'wav'])
			if (exists('$key.$ext')) return path('$key.$ext');
		return null;
	}
}
