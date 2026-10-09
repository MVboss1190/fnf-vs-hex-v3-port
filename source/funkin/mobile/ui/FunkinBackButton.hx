package funkin.mobile.ui;

import mobile.objects.TouchButton;

/**
 * VS Hex compatibility: V-Slice's on-screen back button, built from Psych mobile's touch pad "B" button.
 */
class FunkinBackButton extends TouchButton
{
	public function new(x:Float = 0, y:Float = 0, color:FlxColor = FlxColor.WHITE, ?onBack:Void->Void, alpha:Float = 0.7)
	{
		super(x, y);
		label = new FlxSprite();
		loadGraphic(Paths.image('touchpad/bg', 'mobile'));
		label.loadGraphic(Paths.image('touchpad/B', 'mobile'));
		scale.set(0.3, 0.3);
		updateHitbox();
		updateLabelPosition();
		statusBrightness = [1, 0.8, 0.4];
		statusIndicatorType = BRIGHTNESS;
		indicateStatus();
		bounds.makeGraphic(Std.int(width - 40), Std.int(height - 40), FlxColor.TRANSPARENT);
		centerBounds();
		immovable = true;
		solid = moves = false;
		label.antialiasing = antialiasing = ClientPrefs.data.antialiasing;
		this.color = color;
		this.alpha = alpha;
		parentAlpha = alpha;
		if (onBack != null) onUp.callback = onBack;
	}
}
