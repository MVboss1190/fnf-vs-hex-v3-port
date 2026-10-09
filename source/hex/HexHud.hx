package hex;

import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxStringUtil;
import funkin.play.PlayStatePlaylist;
import kade.hex.objects.HexTransitional;
import kade.hex.states.HexDialogueState;
import kade.hex.substates.HexEvilGameOver;
import kade.hex.substates.HexGameOverMenu;
import kade.hex.substates.HexPauseMenu;
import objects.Note;
import states.PlayState;

/**
 * VS Hex's in-song HUD, ported from its HEX-HUD and KE-QOL modules:
 * the transition screens, letterbox bars and circles, song timer, Kade Engine style
 * health bar and score, Hex's pause and game over menus, and the story dialogue around songs.
 */
class HexHud
{
	var game:PlayState;

	public var transitional:HexTransitional;
	var trans2:HexTransitional;

	var timer:FlxText;
	var didFade:Bool = false;

	var topBar:FlxSprite;
	var bottomBar:FlxSprite;
	var leftCircle:FlxSprite;
	var rightCircle:FlxSprite;

	public var healthBarBG:FlxSprite;
	public var healthBar:FlxBar;
	public var scoreText:FlxText;
	var healthLerp:Float = 1;
	var shownText:String = null;

	var barsCam:FlxCamera;
	var overCam:FlxCamera;
	var pauseCam:FlxCamera;

	var elapsedTime:Float = 0;
	var initialTrans:Bool = false;

	/** Set while a story transition or closing dialogue holds the end of the song. */
	public var holdingEnd(default, null):Bool = false;
	public var endReleased(default, null):Bool = false;

	/** Next game over uses the "evil" screen (set by songs that kill you through a mechanic). */
	public var goEvil:Bool = false;

	static final DIALOGUE_NAMES:Map<String, String> = [
		'dunk' => 'Dunk',
		'ram' => 'R.A.M.',
		'hello-world' => 'Hello World',
		'glitcher' => 'Glitcher',
		'cooling' => 'Cooling',
		'detected' => 'Detected',
		'bit' => 'B.I.T.',
		'jumpin' => "Jumpin'",
		'headbasher' => 'Headbasher'
	];

	public function new(game:PlayState)
	{
		this.game = game;

		overCam = new FlxCamera();
		overCam.bgColor = 0x00000000;
		insertCamera(overCam, FlxG.cameras.list.indexOf(game.camHUD) + 1);

		pauseCam = new FlxCamera();
		pauseCam.bgColor = 0x00000000;
		insertCamera(pauseCam, FlxG.cameras.list.indexOf(overCam) + 1);

		barsCam = new FlxCamera();
		barsCam.bgColor = 0x00000000;
		insertCamera(barsCam, FlxG.cameras.list.indexOf(game.camHUD));

		HexPauseMenu.warm();

		trans2 = new HexTransitional();
		trans2.forceOut();
		trans2.cameras = [overCam];
		trans2.scrollFactor.set();
		game.add(trans2);

		transitional = new HexTransitional();
		transitional.forceIn();
		transitional.cameras = [overCam];
		transitional.scrollFactor.set();
		game.add(transitional);

		// Letterbox bars and circles, under the HUD.
		topBar = makeBar(-4);
		bottomBar = makeBar(FlxG.height - 67);

		leftCircle = new FlxSprite().loadGraphic(HexAssets.image('ui/hex/circle'));
		leftCircle.scrollFactor.set();
		leftCircle.x = -2;
		leftCircle.y = FlxG.height - leftCircle.height;
		leftCircle.cameras = [barsCam];
		game.add(leftCircle);

		rightCircle = new FlxSprite().loadGraphic(HexAssets.image('ui/hex/circle'));
		rightCircle.scrollFactor.set();
		rightCircle.cameras = [barsCam];
		rightCircle.scale.set(1.5, 1.5);
		rightCircle.flipX = true;
		rightCircle.origin.set(0, 0);
		rightCircle.x = FlxG.width - rightCircle.width * 1.5;
		rightCircle.y = FlxG.height - rightCircle.height;
		game.add(rightCircle);

		timer = new FlxText(FlxG.width / 2, timerY(), 0, '', 20);
		timer.alpha = 0;
		timer.setFormat(funkin.Paths.font('ui/fonts/Arista'), 42, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		timer.scrollFactor.set();
		timer.cameras = [game.camHUD];
		game.add(timer);

		buildHealthBar();
		centerStrums();

		// Psych's own bar, score and time readouts make way for Hex's.
		game.timeBar.visible = false;
		game.timeTxt.visible = false;
		game.scoreTxt.visible = false;
		game.healthBar.visible = false;
		game.updateIconsPosition = updateIconsPosition;
		for (icon in [game.iconP1, game.iconP2])
			icon.y = healthBarBG.y + healthBarBG.height / 2 - icon.height / 2;
	}

	/**
	 * Flixel 5.6 can only append cameras, so re-add the ones that should sit above.
	 */
	static function insertCamera(cam:FlxCamera, index:Int):Void
	{
		var above:Array<FlxCamera> = FlxG.cameras.list.slice(index);
		for (c in above) FlxG.cameras.remove(c, false);
		FlxG.cameras.add(cam, false);
		for (c in above) FlxG.cameras.add(c, c == FlxG.camera);
	}

	function makeBar(y:Float):FlxSprite
	{
		var bar:FlxSprite = new FlxSprite(-4, y);
		bar.makeGraphic(1, 1, 0xFFFFFFFF);
		bar.color = 0xFF000000;
		bar.scale.set(FlxG.width + 8, 67 + 4);
		bar.updateHitbox();
		bar.scrollFactor.set();
		bar.cameras = [barsCam];
		game.add(bar);
		return bar;
	}

	inline function songId():String
		return HexSong.current != null ? HexSong.current.id : '';

	function barLow():Bool
		return songId() == 'headbasher' || !ClientPrefs.data.downScroll;

	function timerY():Float
		return (ClientPrefs.data.downScroll && songId() != 'headbasher') ? FlxG.height - 57 : 10;

	function buildHealthBar():Void
	{
		var low:Bool = barLow();

		healthBarBG = new FlxSprite().loadGraphic(HexAssets.image('ui/hex/hex_healthBar'));
		healthBarBG.scale.set(1.14, 1.02);
		healthBarBG.updateHitbox();
		healthBarBG.y = low ? FlxG.height * 0.9 : FlxG.height * 0.1;
		healthBarBG.x = FlxG.width / 2 - healthBarBG.width / 2;
		healthBarBG.scrollFactor.set();
		healthBarBG.cameras = [game.camHUD];

		healthLerp = game.health;
		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this, 'healthLerp', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.cameras = [game.camHUD];

		var leftName:String = game.dad != null && game.dad.vsData != null ? '' + game.dad.vsData.name : '';
		var rightName:String = game.boyfriend != null && game.boyfriend.vsData != null ? '' + game.boyfriend.vsData.name : '';
		var colorLeft:FlxColor = FlxColor.fromRGB(66, 250, 244);
		var colorRight:FlxColor = FlxColor.fromRGB(48, 177, 209);
		if (rightName.startsWith('Hex')) colorRight = colorLeft;
		if (leftName.startsWith('Iris') || leftName.contains('Glitcher') || leftName.contains('Detected')) colorLeft = FlxColor.fromRGB(239, 58, 45);
		if (leftName.startsWith('Slasher')) colorLeft = FlxColor.fromRGB(227, 37, 101);
		if (leftName.startsWith('Whitty')) colorLeft = FlxColor.fromRGB(48, 50, 86);
		if (leftName.startsWith('Coda')) colorLeft = FlxColor.fromRGB(247, 101, 69);
		if (leftName.startsWith('Richard')) colorLeft = FlxColor.fromRGB(58, 84, 197);
		healthBar.createFilledBar(colorLeft, colorRight);

		// The bar goes behind the HUD icons.
		game.uiGroup.insert(0, healthBar);
		game.uiGroup.insert(1, healthBarBG);

		scoreText = new FlxText(healthBarBG.x + healthBarBG.width - 190, healthBarBG.y + (low ? 40 : -40), 0, '', 20);
		scoreText.setFormat(funkin.Paths.font('ui/fonts/AristaLight'), 26, 0xFFFFFFFF, RIGHT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		scoreText.scrollFactor.set();
		scoreText.cameras = [game.camHUD];
		game.uiGroup.add(scoreText);
		updateScoreText();
	}

	/**
	 * KE layout: both strumlines next to each other in the middle, unless Psych puts them elsewhere (middlescroll).
	 */
	function centerStrums():Void
	{
		if (ClientPrefs.data.middleScroll) return;
		var spacing:Float = Note.swagWidth;
		var lineWidth:Float = spacing * 4;
		var opX:Float = FlxG.width / 2 - lineWidth / 2 - (lineWidth - spacing);
		var bfX:Float = FlxG.width / 2 - lineWidth / 2 + (lineWidth - spacing);
		for (i => strum in game.opponentStrums.members)
			strum.x = opX + spacing * i;
		for (i => strum in game.playerStrums.members)
			strum.x = bfX + spacing * i;
	}

	function updateIconsPosition():Void
	{
		var percent:Float = 1 - healthLerp / 2;
		var center:Float = healthBar.x + healthBar.width * percent;
		var iconOffset:Int = 26;
		game.iconP1.x = center + (150 * game.iconP1.scale.x - 150) / 2 - iconOffset;
		game.iconP2.x = center - (150 * game.iconP2.scale.x) / 2 - iconOffset * 2;
	}

	function updateScoreText():Void
	{
		var sicks:Int = 0, goods:Int = 0, hits:Int = 0;
		for (r in game.ratingsData)
		{
			hits += r.hits;
			if (r.name == 'sick') sicks = r.hits;
			if (r.name == 'good') goods = r.hits;
		}
		var total:Int = hits + game.songMisses;
		var acc:Float = total == 0 ? 1 : (sicks + goods - game.songMisses) / total;
		acc = Math.max(-1, Math.min(1, acc));

		var text:String = 'Score: ' + FlxStringUtil.formatMoney(Math.max(game.songScore, 0), false, true);
		if (acc < 0) text += ' • Accuracy: 0% (' + Std.int(acc * 100) + '%)';
		else text += ' • Accuracy: ' + Std.int(acc * 100) + '%';
		if (text == shownText) return;
		shownText = text;
		scoreText.text = text;
		scoreText.x = FlxG.width / 2 - scoreText.width / 2;
	}

	/**
	 * The song's countdown waits for the opening transition (and story dialogue), like in Hex.
	 */
	public function update(elapsed:Float):Void
	{
		elapsedTime += elapsed;
		if (elapsedTime >= 0.5 && !initialTrans)
		{
			initialTrans = true;
			var preId:String = storyDialogueId('Pre-');
			if (preId != null)
			{
				openStoryDialogue(preId, function()
				{
					transitional.forceIn();
					transitional.transitionOut();
					game.startCountdown();
				});
			}
			else
			{
				transitional.transitionOut();
				game.startCountdown();
			}
		}

		healthLerp = FlxMath.lerp(healthLerp, game.health, Math.min(1, 0.15 * elapsed * 60));
		updateScoreText();

		if (FlxG.sound.music != null && !game.startingSong)
		{
			if (!didFade)
			{
				timer.alpha += 0.02 * elapsed * 60;
				if (timer.alpha >= 1) didFade = true;
			}
			var totalSeconds:Float = Math.max(0, (FlxG.sound.music.length - Conductor.songPosition) / 1000);
			var minutes:Int = Std.int(totalSeconds / 60);
			var seconds:Int = Std.int(totalSeconds % 60);
			timer.text = minutes + ':' + (seconds < 10 ? '0' : '') + seconds;
			timer.x = FlxG.width / 2 - timer.width / 2;
			timer.y = timerY();
		}
	}

	public function openPause():Void
	{
		if (!transitional.complete || !initialTrans) return;
		var pause:HexPauseMenu = new HexPauseMenu();
		pause.trans = transitional;
		pause.camera = pauseCam;
		game.openSubState(pause);
	}

	/** Opens Hex's game over screen. Returns false if it can't be shown yet. */
	public function gameOver():Bool
	{
		if (!transitional.complete || !initialTrans) return false;
		var length:Float = FlxG.sound.music != null && FlxG.sound.music.length > 0 ? FlxG.sound.music.length : 1;
		var percentage:Float = Conductor.songPosition / length;

		var sub:Dynamic = goEvil ? new HexEvilGameOver() : new HexGameOverMenu();
		if (!goEvil) sub.percentage = percentage;
		sub.trans = transitional;
		sub.camera = pauseCam;
		goEvil = false;
		game.openSubState(sub);
		return true;
	}

	/**
	 * Called at the end of a story song. Returns true when the end is being held for a transition
	 * or the closing dialogue; PlayState.endSong is called again once it's done.
	 */
	public function holdSongEnd():Bool
	{
		if (!PlayState.isStoryMode || endReleased) return false;
		if (holdingEnd) return true;

		var lastSong:Bool = PlayState.storyPlaylist.length <= 1;
		holdingEnd = true;
		if (!lastSong)
		{
			transitional.transitionIn();
			transitional.onComplete = function(out:Bool)
			{
				if (out) return;
				transitional.onComplete = null;
				release();
			};
			return true;
		}

		var postId:String = storyDialogueId('Post-');
		if (postId == null)
		{
			holdingEnd = false;
			return false;
		}
		openStoryDialogue(postId, function()
		{
			transitional.forceIn();
			new FlxTimer().start(0.01, function(_) release());
		});
		return true;
	}

	function release():Void
	{
		holdingEnd = false;
		endReleased = true;
		game.endSong();
	}

	function storyDialogueId(prefix:String):String
	{
		if (!PlayState.isStoryMode) return null;
		var name:String = DIALOGUE_NAMES.get(songId());
		if (name == null) return null;
		var id:String = prefix + name;
		if (HexDialogueState.played.indexOf(id) != -1) return null;
		if (!HexAssets.exists('gameplay/hex/story/dialogue/$id.txt')) return null;
		return id;
	}

	function openStoryDialogue(id:String, after:Void->Void):Void
	{
		HexDialogueState.played.push(id);
		var scene:HexDialogueState = new HexDialogueState();
		scene.dialogueId = id;
		scene.closeCallback = after;
		scene.camera = pauseCam;
		game.persistentUpdate = false;
		game.persistentDraw = false;
		game.openSubState(scene);
	}

	public function destroy():Void
	{
		for (cam in [overCam, pauseCam, barsCam])
			if (cam != null && FlxG.cameras.list.contains(cam)) FlxG.cameras.remove(cam);
	}
}
