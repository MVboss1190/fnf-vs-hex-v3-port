package funkin.ui.story;

/**
 * VS Hex compatibility: a Hex story level ("Week X"...), from `ui/story-mode/levels/<id>.json`.
 */
class Level
{
	public var id(default, null):String;
	var _data:Dynamic;

	public function new(id:String, data:Dynamic)
	{
		this.id = id;
		this._data = data;
	}

	public function getTitle():String
		return _data.name != null ? StringTools.replace(_data.name, '(Hex) ', '') : id;

	public function getSongs():Array<String>
		return _data.songs != null ? (_data.songs : Array<String>).copy() : [];

	public function isVisible():Bool
		return _data.visible != false;
}
