package funkin.ui;

/**
 * VS Hex compatibility: V-Slice's MusicBeatSubState as Psych's MusicBeatSubstate.
 */
class MusicBeatSubState extends backend.MusicBeatSubstate
{
	public function new(?bgColor:FlxColor)
	{
		super();
		if (bgColor != null) this.bgColor = bgColor;
	}
}
