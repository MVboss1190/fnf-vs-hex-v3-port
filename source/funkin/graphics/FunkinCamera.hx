package funkin.graphics;

/**
 * VS Hex compatibility: V-Slice's camera, a plain FlxCamera with an id.
 */
class FunkinCamera extends FlxCamera
{
	public var id:String;

	public function new(id:String = 'unknown', x:Int = 0, y:Int = 0, width:Int = 0, height:Int = 0, zoom:Float = 0)
	{
		super(x, y, width, height, zoom);
		this.id = id;
	}
}
