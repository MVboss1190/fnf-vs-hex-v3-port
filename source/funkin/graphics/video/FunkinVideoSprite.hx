package funkin.graphics.video;

#if VIDEOS_ALLOWED
/**
 * VS Hex compatibility: V-Slice's video sprite, hxvlc's FlxVideoSprite.
 * Videos are inside the APK on mobile, so they are copied to a temporary file before playing.
 */
class FunkinVideoSprite extends hxvlc.flixel.FlxVideoSprite
{
	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
	}

	public function loadAsset(path:String):Bool
	{
		var bytes = openfl.utils.Assets.getBytes(path);
		if (bytes == null) return false;
		return load(bytes);
	}
}
#else
class FunkinVideoSprite extends FlxSprite
{
	public function new(x:Float = 0, y:Float = 0)
		super(x, y);

	public function loadAsset(path:String):Bool
		return false;
}
#end
