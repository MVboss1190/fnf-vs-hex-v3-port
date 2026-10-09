package funkin.assets;

class FunkinAssetCache
{
	public static var instance(get, null):FunkinAssetCache;

	static function get_instance():FunkinAssetCache
	{
		if (instance == null) instance = new FunkinAssetCache();
		return instance;
	}

	function new() {}

	public function removeSound(key:String):Bool
	{
		openfl.utils.Assets.cache.removeSound(key);
		return true;
	}
}
