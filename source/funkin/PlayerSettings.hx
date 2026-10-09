package funkin;

import funkin.input.Controls;

/**
 * VS Hex compatibility: V-Slice's per-player settings, only player one's controls are used.
 */
class PlayerSettings
{
	public static var player1(get, null):PlayerSettings;

	static function get_player1():PlayerSettings
	{
		if (player1 == null) player1 = new PlayerSettings();
		return player1;
	}

	public var controls(default, null):Controls = new Controls();

	function new() {}

	public function saveControls():Void
		ClientPrefs.saveSettings();
}
