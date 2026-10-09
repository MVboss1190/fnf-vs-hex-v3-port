package funkin;

import openfl.utils.Assets as OpenFlAssets;

/**
 * VS Hex compatibility: V-Slice's `funkin.Assets`, on top of OpenFL's asset system.
 */
class Assets
{
	public static function exists(path:String, ?type:openfl.utils.AssetType):Bool
		return path != null && OpenFlAssets.exists(path, type);

	public static function getText(path:String):String
		return OpenFlAssets.exists(path) ? OpenFlAssets.getText(path) : null;

	public static function getBytes(path:String):haxe.io.Bytes
		return OpenFlAssets.exists(path) ? OpenFlAssets.getBytes(path) : null;

	public static function getBitmapData(path:String, useCache:Bool = true, ?allowCompressedTextures:Bool, ?_:Bool):openfl.display.BitmapData
		return OpenFlAssets.getBitmapData(path, useCache);

	public static function list(?type:openfl.utils.AssetType):Array<String>
		return OpenFlAssets.list(type);
}
