package funkin.graphics;

/**
 * VS Hex compatibility: V-Slice's `FunkinSprite` helpers on a plain FlxSprite.
 * Texture keys are paths from the mod root without extension.
 */
class FunkinSprite extends FlxSprite
{
	public static function create(x:Float = 0, y:Float = 0, key:String):FunkinSprite
	{
		var spr:FunkinSprite = new FunkinSprite(x, y);
		spr.loadTexture(key);
		return spr;
	}

	public static function createSparrow(x:Float = 0, y:Float = 0, key:String):FunkinSprite
	{
		var spr:FunkinSprite = new FunkinSprite(x, y);
		spr.loadSparrow(key);
		return spr;
	}

	public function loadTexture(key:String):FunkinSprite
	{
		var graphic = hex.HexAssets.image(key);
		if (graphic != null) loadGraphic(graphic);
		return this;
	}

	public function loadSparrow(key:String):FunkinSprite
	{
		var atlas = hex.HexAssets.atlas(key);
		if (atlas != null) frames = atlas;
		return this;
	}

	public function makeSolidColor(width:Int, height:Int, color:FlxColor = FlxColor.WHITE):FunkinSprite
	{
		makeGraphic(1, 1, color);
		scale.set(width, height);
		updateHitbox();
		return this;
	}

	public function isAnimationFinished():Bool
		return animation.curAnim == null || animation.curAnim.finished;
}
