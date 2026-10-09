package funkin.mobile.input;

/**
 * VS Hex compatibility: whether a keyboard or gamepad is in use instead of the touch screen.
 */
class ControlsHandler
{
	public static var hasExternalInputDevice(get, never):Bool;

	static function get_hasExternalInputDevice():Bool
	{
		#if mobile
		return FlxG.gamepads.numActiveGamepads > 0;
		#else
		return true;
		#end
	}
}
