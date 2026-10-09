package hex;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import objects.Character;
import states.PlayState;

/**
 * Plays the V-Slice song events of a VS Hex chart inside Psych's PlayState:
 * FocusCamera, ZoomCamera, SetCameraBop, PlayAnimation and Hex's SwitchCharacters.
 */
class HexEvents
{
	var game:PlayState;
	var events:Array<Dynamic>;
	var index:Int = 0;

	/** Characters made ahead of time for SwitchCharacters, by id. */
	var prepared:Map<String, Character> = [];

	var camTween:FlxTween;
	var zoomTween:FlxTween;

	/** Camera bop, in beats, like V-Slice's SetCameraBop. */
	public var bopRate:Float = 4;
	public var bopIntensity:Float = 1;
	public var bopOffset:Float = 0;

	public function new(game:PlayState, events:Array<Dynamic>)
	{
		this.game = game;
		this.events = events != null ? events : [];
		prepare();
	}

	/** True when the chart moves the camera itself, so Psych's per-section camera should stay out of it. */
	public function controlsCamera():Bool
	{
		for (e in events)
			if (e.e == 'FocusCamera') return true;
		return false;
	}

	function prepare():Void
	{
		if (game.hexStage == null) return;
		for (e in events)
		{
			if (e.e != 'SwitchCharacters' || e.v == null) continue;
			var id:String = e.v.id;
			if (id == null || prepared.exists(id) || !HexCharacter.exists(id)) continue;

			var target:Int = readInt(e.v.target, 0);
			var char:Character = new Character(0, 0, id, target == 0);
			char.visible = false;
			char.alpha = 0.00001;
			groupFor(target).add(char);
			game.hexStage.placeCharacter(char, roleFor(target));
			prepared.set(id, char);
		}
	}

	/**
	 * Runs every event that has come up. `force` replays everything up to the current time (used after skipping).
	 */
	public function update():Void
	{
		while (index < events.length && events[index].t <= Conductor.songPosition)
		{
			var e:Dynamic = events[index++];
			try
			{
				trigger(e.e, e.v);
			}
			catch (err:Dynamic)
			{
				trace('[HEX] Event ${e.e} failed: $err');
			}
		}
	}

	public function trigger(name:String, v:Dynamic):Void
	{
		switch (name)
		{
			case 'FocusCamera':
				focusCamera(v);
			case 'ZoomCamera':
				zoomCamera(v);
			case 'SetCameraBop':
				bopRate = readFloat(v.rate, 4);
				bopIntensity = readFloat(v.intensity, 1);
				bopOffset = readFloat(v.offset, 0);
			case 'PlayAnimation':
				var target:Dynamic = targetByName(v.target);
				if (target == null) return;
				if (Std.isOfType(target, Character))
				{
					var char:Character = cast target;
					if (char.hasAnimation(v.anim))
					{
						char.playAnim(v.anim, v.force == true);
						char.specialAnim = true;
					}
				}
				else
				{
					var spr:FlxSprite = cast target;
					if (spr.animation.exists(v.anim)) spr.animation.play(v.anim, v.force == true);
				}
			case 'SwitchCharacters':
				switchCharacters(v);
			default:
				// CharacterLook and other visual-only Hex events need the original shaders; skipped for now.
		}
	}

	/**
	 * Camera bop on the beat, V-Slice style. Returns true when it bopped.
	 */
	public function beatHit(beat:Int):Bool
	{
		if (bopRate <= 0 || !ClientPrefs.data.camZooms) return false;
		var rate:Int = Std.int(Math.max(1, Math.round(bopRate)));
		if ((beat - Math.round(bopOffset)) % rate != 0) return false;
		if (FlxG.camera.zoom < 1.35)
		{
			FlxG.camera.zoom += 0.015 * bopIntensity * game.camZoomingMult;
			game.camHUD.zoom += 0.03 * bopIntensity * game.camZoomingMult;
		}
		return true;
	}

	function focusCamera(v:Dynamic):Void
	{
		var charIndex:Int = -1;
		var offX:Float = 0;
		var offY:Float = 0;
		var ease:String = 'CLASSIC';
		var duration:Float = 4;

		if (Std.isOfType(v, Int) || Std.isOfType(v, Float) || Std.isOfType(v, String))
			charIndex = Std.parseInt(Std.string(v));
		else if (v != null)
		{
			charIndex = readInt(v.char, 0);
			offX = readFloat(v.x, 0);
			offY = readFloat(v.y, 0);
			if (v.ease != null) ease = v.ease;
			duration = readFloat(v.duration, 4);
		}

		var target:FlxPoint = FlxPoint.get(offX, offY);
		var char:Character = switch (charIndex)
		{
			case 0: game.boyfriend;
			case 1: game.dad;
			case 2: game.gf;
			default: null;
		}
		if (char != null)
		{
			var focus:FlxPoint = focusOf(char);
			target.add(focus.x, focus.y);
			focus.put();
		}

		if (camTween != null) camTween.cancel();
		switch (ease)
		{
			case 'CLASSIC':
				game.camFollow.setPosition(target.x, target.y);
			case 'INSTANT':
				game.camFollow.setPosition(target.x, target.y);
				FlxG.camera.snapToTarget();
			default:
				var seconds:Float = duration * Conductor.stepCrochet / 1000;
				camTween = FlxTween.tween(game.camFollow, {x: target.x, y: target.y}, Math.max(seconds, 0.01), {ease: easeFrom(ease, v != null ? v.easeDir : null)});
		}
		target.put();
	}

	function zoomCamera(v:Dynamic):Void
	{
		var zoom:Float = readFloat(v.zoom, 1);
		var duration:Float = readFloat(v.duration, 4);
		var mode:String = v.mode != null ? v.mode : 'direct';
		var ease:String = v.ease != null ? v.ease : 'linear';

		var stageZoom:Float = game.hexStage != null ? game.hexStage.cameraZoom : 1;
		var target:Float = (mode == 'stage') ? zoom * stageZoom : zoom;
		if (zoomTween != null) zoomTween.cancel();

		if (ease == 'INSTANT')
		{
			game.defaultCamZoom = target;
			FlxG.camera.zoom = target;
			return;
		}
		var seconds:Float = duration * Conductor.stepCrochet / 1000;
		zoomTween = FlxTween.num(game.defaultCamZoom, target, Math.max(seconds, 0.01), {ease: easeFrom(ease, v.easeDir)}, function(z:Float) game.defaultCamZoom = z);
	}

	function switchCharacters(v:Dynamic):Void
	{
		if (game.hexStage == null) return;
		var id:String = v.id;
		var made:Character = prepared.get(id);
		if (made == null) return;

		var target:Int = readInt(v.target, 0);
		var standing:Character = switch (target)
		{
			case 1: game.dad;
			case 2: game.gf;
			default: game.boyfriend;
		}
		if (standing == made) return;

		game.hexStage.placeCharacter(made, roleFor(target));
		made.x += readFloat(v.offsetX, 0);
		made.y += readFloat(v.offsetY, 0);
		if (made.vsFocusPoint != null) made.vsFocusPoint.add(readFloat(v.offsetX, 0), readFloat(v.offsetY, 0));

		// Keep the current pose so the swap doesn't snap back to idle mid-note.
		var anim:String = standing != null ? standing.getAnimationName() : null;
		if (anim != null && made.hasAnimation(anim)) made.playAnim(anim, true);

		made.visible = true;
		made.alpha = 1;
		var fade:Float = readFloat(v.fade, 0);
		if (standing != null)
		{
			if (fade > 0)
			{
				made.alpha = 0;
				FlxTween.tween(made, {alpha: 1}, fade);
				var old:Character = standing;
				FlxTween.tween(old, {alpha: 0}, fade, {onComplete: function(_) old.visible = false});
			}
			else
				standing.visible = false;
			if (!prepared.exists(standing.curCharacter)) prepared.set(standing.curCharacter, standing);
		}

		switch (target)
		{
			case 1:
				game.dad = made;
				game.iconP2.changeIcon(made.healthIcon);
			case 2:
				game.gf = made;
			default:
				game.boyfriend = made;
				game.iconP1.changeIcon(made.healthIcon);
		}
		game.reloadHealthBarColors();
	}

	function focusOf(char:Character):FlxPoint
	{
		if (char.vsFocusPoint != null) return FlxPoint.get(char.vsFocusPoint.x, char.vsFocusPoint.y);
		var mid:FlxPoint = char.getMidpoint();
		return mid;
	}

	function targetByName(name:String):Dynamic
	{
		if (name == null) return null;
		return switch (name.toLowerCase())
		{
			case 'bf' | 'boyfriend' | 'player': game.boyfriend;
			case 'dad' | 'opponent': game.dad;
			case 'gf' | 'girlfriend': game.gf;
			default: game.hexStage != null ? game.hexStage.props.get(name) : null;
		}
	}

	function groupFor(target:Int):flixel.group.FlxSpriteGroup
	{
		return switch (target)
		{
			case 1: game.dadGroup;
			case 2: game.gfGroup;
			default: game.boyfriendGroup;
		}
	}

	static function roleFor(target:Int):String
		return target == 1 ? 'dad' : (target == 2 ? 'gf' : 'bf');

	static function readFloat(value:Dynamic, fallback:Float):Float
	{
		if (value == null) return fallback;
		var f:Float = Std.parseFloat(Std.string(value));
		return Math.isNaN(f) ? fallback : f;
	}

	static function readInt(value:Dynamic, fallback:Int):Int
	{
		if (value == null) return fallback;
		var i:Null<Int> = Std.parseInt(Std.string(value));
		return i == null ? fallback : i;
	}

	/**
	 * V-Slice ease names: "linear", "INSTANT", "CLASSIC", or an ease family ("cube", "sine"...) plus a direction.
	 */
	public static function easeFrom(name:String, ?dir:String):Float->Float
	{
		if (name == null || name == 'linear' || name == 'CLASSIC' || name == 'INSTANT') return FlxEase.linear;
		var key:String = name;
		if (dir != null && dir.length > 0) key = name + dir;
		else if (!name.toLowerCase().endsWith('in') && !name.toLowerCase().endsWith('out')) key = name + 'InOut';
		return psychlua.LuaUtils.getTweenEaseByString(key);
	}
}
