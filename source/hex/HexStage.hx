package hex;

import backend.StageData.StageFile;
import flixel.FlxBasic;
import flixel.FlxState;
import flixel.group.FlxSpriteGroup;
import objects.Character;
import openfl.display.BlendMode;

/**
 * A VS Hex stage (`gameplay/stages/<id>/<id>.json`, V-Slice format) built inside Psych's PlayState.
 *
 * Props and characters are layered by their `zIndex`, characters stand on their feet positions,
 * and props with a `danceEvery` bop on the beat, all as V-Slice does it.
 */
class HexStage
{
	public var id(default, null):String;
	public var data(default, null):Dynamic;
	public var cameraZoom(default, null):Float = 1;

	/** Props by name, so song scripts can find them. */
	public var props(default, null):Map<String, FlxSprite> = [];

	var dancers:Array<{sprite:FlxSprite, every:Float, idle:String, left:String, right:String, danced:Bool}> = [];

	public static function path(id:String):String
		return 'gameplay/stages/$id/$id.json';

	public static function exists(id:String):Bool
		return id != null && HexAssets.exists(path(id));

	public static function load(id:String):HexStage
	{
		if (!exists(id)) return null;
		var json:Dynamic = HexAssets.getJson(path(id));
		if (json == null) return null;
		return new HexStage(id, json);
	}

	function new(id:String, data:Dynamic)
	{
		this.id = id;
		this.data = data;
		this.cameraZoom = data.cameraZoom != null ? data.cameraZoom : 1;
	}

	/**
	 * Stage settings in Psych's format. Characters are placed by `placeCharacters`, so positions stay zero.
	 */
	public function psychData():StageFile
	{
		var chars:Dynamic = data.characters != null ? data.characters : {};
		return {
			directory: '',
			defaultZoom: cameraZoom,
			stageUI: 'normal',
			boyfriend: [0, 0],
			girlfriend: [0, 0],
			opponent: [0, 0],
			hide_girlfriend: Reflect.field(chars, 'gf') == null,
			camera_boyfriend: [0, 0],
			camera_opponent: [0, 0],
			camera_girlfriend: [0, 0],
			camera_speed: 1
		};
	}

	public function characterData(role:String):Dynamic
	{
		if (data.characters == null) return null;
		return Reflect.field(data.characters, role);
	}

	/**
	 * Builds the props and adds them to `state` together with the character groups, sorted by zIndex.
	 */
	public function build(state:FlxState, gfGroup:FlxSpriteGroup, dadGroup:FlxSpriteGroup, bfGroup:FlxSpriteGroup):Void
	{
		var layers:Array<{z:Float, obj:FlxBasic}> = [];

		var propList:Array<Dynamic> = data.props != null ? data.props : [];
		for (prop in propList)
		{
			var spr:FlxSprite = makeProp(prop);
			if (spr == null) continue;
			layers.push({z: prop.zIndex != null ? prop.zIndex : 0, obj: spr});
		}

		for (entry in [{role: 'gf', group: gfGroup}, {role: 'dad', group: dadGroup}, {role: 'bf', group: bfGroup}])
		{
			if (entry.group == null) continue;
			var charData:Dynamic = characterData(entry.role);
			var z:Float = (charData != null && charData.zIndex != null) ? charData.zIndex : 0;
			layers.push({z: z, obj: entry.group});
		}

		// Stable sort, so equal zIndex keeps the file's order like V-Slice does.
		var indexed = [for (i => l in layers) {i: i, l: l}];
		indexed.sort((a, b) -> a.l.z == b.l.z ? a.i - b.i : (a.l.z < b.l.z ? -1 : 1));
		for (entry in indexed) state.add(entry.l.obj);
	}

	/**
	 * Puts a character on its spot for `role` ('bf', 'dad' or 'gf').
	 */
	public function placeCharacter(char:Character, role:String):Void
	{
		if (char == null) return;
		var charData:Dynamic = characterData(role);
		var position:Array<Float> = (charData != null && charData.position != null) ? charData.position : [0, 0];
		var cameraOffsets:Array<Float> = (charData != null && charData.cameraOffsets != null) ? charData.cameraOffsets : [0, 0];
		var stageScale:Float = (charData != null && charData.scale != null) ? charData.scale : 1;

		if (char.vsMode)
			char.placeVSlice(position, cameraOffsets, stageScale);
		else
		{
			// A Psych character on a Hex stage: stand it on the same spot.
			char.updateHitbox();
			char.x = position[0] - char.width / 2;
			char.y = position[1] - char.height;
		}

		if (charData != null)
		{
			if (charData.scroll != null) char.scrollFactor.set(charData.scroll[0], charData.scroll[1]);
			if (charData.alpha != null) char.alpha = charData.alpha;
			if (charData.angle != null) char.angle = charData.angle;
		}
	}

	function makeProp(prop:Dynamic):FlxSprite
	{
		var assetPath:String = prop.assetPath != null ? HexAssets.clean(prop.assetPath) : '';
		var spr:FlxSprite = new FlxSprite();
		var scale:Array<Float> = readPair(prop.scale, 1);

		if (assetPath.startsWith('#'))
		{
			// Solid colour rectangle, its "scale" is its size.
			spr.makeGraphic(1, 1, FlxColor.fromString(assetPath));
			spr.scale.set(scale[0], scale[1]);
			spr.updateHitbox();
		}
		else
		{
			var anims:Array<Dynamic> = prop.animations != null ? prop.animations : [];
			if (anims.length > 0)
			{
				var frames = HexAssets.atlas(assetPath);
				if (frames == null)
				{
					trace('[HEX] Missing stage prop $assetPath');
					return null;
				}
				spr.frames = frames;
				for (anim in anims)
				{
					var fps:Int = anim.frameRate != null ? Std.int(anim.frameRate) : 24;
					var indices:Array<Int> = anim.frameIndices;
					if (indices != null && indices.length > 0)
						spr.animation.addByIndices(anim.name, anim.prefix, indices, '', fps, anim.looped == true, anim.flipX == true, anim.flipY == true);
					else
						spr.animation.addByPrefix(anim.name, anim.prefix, fps, anim.looped == true, anim.flipX == true, anim.flipY == true);
				}
			}
			else
			{
				var graphic = HexAssets.image(assetPath);
				if (graphic == null)
				{
					trace('[HEX] Missing stage prop $assetPath');
					return null;
				}
				spr.loadGraphic(graphic);
			}
			spr.scale.set(scale[0], scale[1]);
			spr.updateHitbox();
		}

		var position:Array<Float> = readPair(prop.position, 0);
		spr.setPosition(position[0], position[1]);
		var scroll:Array<Float> = readPair(prop.scroll, 1);
		spr.scrollFactor.set(scroll[0], scroll[1]);
		if (prop.alpha != null) spr.alpha = prop.alpha;
		if (prop.angle != null) spr.angle = prop.angle;
		if (prop.flipX == true) spr.flipX = true;
		if (prop.flipY == true) spr.flipY = true;
		if (prop.color != null) spr.color = FlxColor.fromString(prop.color);
		if (prop.blend != null) spr.blend = blendFrom(prop.blend);
		spr.antialiasing = prop.isPixel == true ? false : ClientPrefs.data.antialiasing;

		if (spr.animation.getNameList().length > 0)
		{
			var start:String = prop.startingAnimation;
			if (start != null && spr.animation.exists(start)) spr.animation.play(start);
			else if (spr.animation.exists('idle')) spr.animation.play('idle');
			else if (spr.animation.exists('danceLeft')) spr.animation.play('danceLeft');

			var every:Float = prop.danceEvery != null ? prop.danceEvery : 0;
			if (every > 0)
				dancers.push({
					sprite: spr,
					every: every,
					idle: spr.animation.exists('idle') ? 'idle' : null,
					left: spr.animation.exists('danceLeft') ? 'danceLeft' : null,
					right: spr.animation.exists('danceRight') ? 'danceRight' : null,
					danced: false
				});
		}

		if (prop.name != null) props.set(prop.name, spr);
		return spr;
	}

	/**
	 * Props with `danceEvery` play their idle (or alternate danceLeft/danceRight) on the beat.
	 */
	public function beatHit(beat:Int):Void
	{
		for (d in dancers)
		{
			var every:Int = Std.int(Math.max(1, Math.round(d.every)));
			if (beat % every != 0) continue;
			if (d.left != null && d.right != null)
			{
				d.danced = !d.danced;
				d.sprite.animation.play(d.danced ? d.right : d.left, true);
			}
			else if (d.idle != null)
				d.sprite.animation.play(d.idle, true);
		}
	}

	static function readPair(value:Dynamic, fallback:Float):Array<Float>
	{
		if (value == null) return [fallback, fallback];
		if (Std.isOfType(value, Array))
		{
			var arr:Array<Dynamic> = cast value;
			return [arr.length > 0 ? arr[0] : fallback, arr.length > 1 ? arr[1] : (arr.length > 0 ? arr[0] : fallback)];
		}
		var f:Float = value;
		return [f, f];
	}

	static function blendFrom(name:String):BlendMode
	{
		return switch (name.toLowerCase())
		{
			case 'add': BlendMode.ADD;
			case 'multiply': BlendMode.MULTIPLY;
			case 'screen': BlendMode.SCREEN;
			case 'darken': BlendMode.DARKEN;
			case 'lighten': BlendMode.LIGHTEN;
			case 'overlay': BlendMode.OVERLAY;
			case 'difference': BlendMode.DIFFERENCE;
			case 'subtract': BlendMode.SUBTRACT;
			case 'invert': BlendMode.INVERT;
			default: BlendMode.NORMAL;
		}
	}
}
