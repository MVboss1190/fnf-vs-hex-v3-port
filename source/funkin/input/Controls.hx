package funkin.input;

import flixel.input.keyboard.FlxKey;

/**
 * VS Hex compatibility: key binding access for Hex's options menu, backed by Psych's ClientPrefs.keyBinds.
 */
class Controls
{
	public function new() {}

	static function psychName(action:String):String
	{
		return switch (action)
		{
			case 'window_fullscreen': 'fullscreen';
			default: action;
		}
	}

	public function getKeysForAction(action:String):Array<FlxKey>
	{
		var keys:Array<FlxKey> = ClientPrefs.keyBinds.get(psychName(action));
		return keys != null ? keys : [];
	}

	public function getControlFromName(name:String):String
		return name;

	public function getDeviceFromName(name:String):String
		return name;

	/**
	 * Replaces `oldKey` (or adds `newKey`) in a keyboard binding.
	 */
	public function replaceBinding(control:String, device:String, newKey:Int, oldKey:Int):Void
	{
		var name:String = psychName(control);
		var keys:Array<FlxKey> = ClientPrefs.keyBinds.get(name);
		if (keys == null)
		{
			keys = [];
			ClientPrefs.keyBinds.set(name, keys);
		}
		var at:Int = keys.indexOf(oldKey);
		if (at >= 0) keys[at] = newKey;
		else keys.push(newKey);
		ClientPrefs.reloadVolumeKeys();
	}
}
