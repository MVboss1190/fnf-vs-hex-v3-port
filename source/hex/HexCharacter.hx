package hex;

import objects.Character;
import objects.Character.AnimArray;

/**
 * Builds Psych characters from VS Hex's V-Slice character files
 * (`gameplay/characters/<id>/<id>.json`), keeping V-Slice's offset and positioning rules.
 */
class HexCharacter
{
	public static function path(id:String):String
		return 'gameplay/characters/$id/$id.json';

	public static function exists(id:String):Bool
		return id != null && HexAssets.exists(path(id));

	public static function getData(id:String):Dynamic
		return exists(id) ? HexAssets.getJson(path(id)) : null;

	/**
	 * Loads `id` into `char`. Returns false when Hex has no such character.
	 */
	@:access(objects.Character)
	public static function load(char:Character, id:String):Bool
	{
		var data:Dynamic = getData(id);
		if (data == null) return false;

		var renderType:String = data.renderType != null ? data.renderType : 'sparrow';
		var assetPath:String = HexAssets.clean(data.assetPath);
		var anims:Array<Dynamic> = data.animations != null ? data.animations : [];

		char.isAnimateAtlas = false;
		char.scale.set(1, 1);
		char.updateHitbox();

		switch (renderType)
		{
			#if flxanimate
			case 'animateatlas' | 'multianimateatlas':
				char.isAnimateAtlas = true;
				char.atlas = new FlxAnimate();
				char.atlas.showPivot = false;
				if (!HexAssets.loadAnimateAtlas(char.atlas, assetPath))
					trace('[HEX] Could not load atlas $assetPath for $id');
			#end
			default:
				// sparrow, multisparrow and packer all end up as atlas frames.
				var sheets:Array<String> = [assetPath];
				for (anim in anims)
				{
					var extra:String = HexAssets.clean(anim.assetPath);
					if (extra.length > 0 && !sheets.contains(extra)) sheets.push(extra);
				}
				char.frames = HexAssets.multiAtlas(sheets);
		}

		char.imageFile = assetPath;
		char.jsonScale = data.scale != null ? data.scale : 1;
		char.scale.set(char.jsonScale, char.jsonScale);
		char.updateHitbox();

		char.positionArray = [0, 0];
		char.cameraPosition = [0, 0];

		var icon:Dynamic = data.healthIcon;
		char.healthIcon = (icon != null && icon.id != null) ? icon.id : id;
		char.vsHealthIcon = icon;

		// V-Slice counts sing time in steps, Psych multiplies a step by it too.
		char.singDuration = data.singTime != null ? data.singTime : 8;
		char.originalFlipX = (data.flipX == true);
		char.flipX = (char.originalFlipX != char.isPlayer);
		char.vocalsFile = '';
		char.editorIsPlayer = null;

		char.noAntialiasing = (data.isPixel == true);
		char.antialiasing = ClientPrefs.data.antialiasing ? !char.noAntialiasing : false;

		char.vsMode = true;
		char.vsData = data;
		char.vsGlobalOffsets = toPoint(data.offsets);
		char.vsCameraOffsets = toPoint(data.cameraOffsets);
		char.vsDanceEvery = data.danceEvery != null ? data.danceEvery : 1;

		char.animationsArray = [];
		for (anim in anims)
		{
			var name:String = '' + anim.name;
			var prefix:String = '' + anim.prefix;
			var fps:Int = anim.frameRate != null ? Std.int(anim.frameRate) : 24;
			var loop:Bool = (anim.looped == true);
			var indices:Array<Int> = anim.frameIndices != null ? anim.frameIndices : [];
			var offsets:Array<Float> = toPoint(anim.offsets);

			if (!char.isAnimateAtlas)
			{
				if (indices.length > 0) char.animation.addByIndices(name, prefix, indices, '', fps, loop, anim.flipX == true, anim.flipY == true);
				else char.animation.addByPrefix(name, prefix, fps, loop, anim.flipX == true, anim.flipY == true);
			}
			#if flxanimate
			else
			{
				// V-Slice atlases name their animations by frame label, Psych's helper looks up symbols, so try both.
				try
				{
					if (indices.length > 0) char.atlas.anim.addBySymbolIndices(name, prefix, indices, fps, loop);
					else char.atlas.anim.addBySymbol(name, prefix, fps, loop);
				}
				catch (e:Dynamic) {}
				@:privateAccess
				if (!char.atlas.anim.animsMap.exists(name))
				{
					try
					{
						char.atlas.anim.addByFrameLabel(name, prefix, fps, loop);
					}
					catch (e:Dynamic) {}
				}
			}
			#end

			var psychAnim:AnimArray = {
				anim: name,
				name: prefix,
				fps: fps,
				loop: loop,
				indices: indices,
				offsets: [Std.int(offsets[0]), Std.int(offsets[1])]
			};
			char.animationsArray.push(psychAnim);
			char.addOffset(name, offsets[0], offsets[1]);
		}

		#if flxanimate
		if (char.isAnimateAtlas) char.copyAtlasValues();
		#end

		char.healthColorArray = iconColor(char.healthIcon);
		return true;
	}

	static function toPoint(value:Dynamic):Array<Float>
	{
		if (value == null) return [0, 0];
		var arr:Array<Dynamic> = cast value;
		return [arr.length > 0 ? arr[0] : 0, arr.length > 1 ? arr[1] : 0];
	}

	/**
	 * V-Slice has no health bar colours, so take the most common opaque colour of the health icon.
	 */
	public static function iconColor(iconId:String):Array<Int>
	{
		var fallback:Array<Int> = [161, 161, 161];
		try
		{
			var graphic = HealthIconPaths.graphic(iconId);
			if (graphic == null || graphic.bitmap == null || !graphic.bitmap.readable) return fallback;

			var bmp = graphic.bitmap;
			var counts:Map<Int, Int> = [];
			var best:Int = -1;
			var bestCount:Int = 0;
			var half:Int = Std.int(bmp.width / 2);
			var y:Int = 0;
			while (y < bmp.height)
			{
				var x:Int = 0;
				while (x < half)
				{
					var c:Int = bmp.getPixel32(x, y);
					if ((c >>> 24) > 200)
					{
						// Quantise so near-identical shades count together, and skip near black outlines.
						var r:Int = (c >> 16) & 0xF0;
						var g:Int = (c >> 8) & 0xF0;
						var b:Int = c & 0xF0;
						if (r + g + b > 96)
						{
							var key:Int = (r << 16) | (g << 8) | b;
							var n:Int = (counts.exists(key) ? counts.get(key) : 0) + 1;
							counts.set(key, n);
							if (n > bestCount)
							{
								bestCount = n;
								best = key;
							}
						}
					}
					x += 2;
				}
				y += 2;
			}
			if (best < 0) return fallback;
			return [(best >> 16) & 0xFF, (best >> 8) & 0xFF, best & 0xFF];
		}
		catch (e:Dynamic)
		{
			return fallback;
		}
	}
}

/**
 * Where a health icon's image lives: Hex keeps them next to the character (`icon-<id>.png`).
 */
class HealthIconPaths
{
	public static function hexPath(iconId:String):String
	{
		if (iconId == null) return null;
		var direct:String = 'gameplay/characters/$iconId/icon-$iconId';
		if (HexAssets.exists('$direct.png')) return direct;
		return null;
	}

	public static function graphic(iconId:String):flixel.graphics.FlxGraphic
	{
		var hex:String = hexPath(iconId);
		if (hex != null) return HexAssets.image(hex, false);
		for (name in ['icons/icon-$iconId', 'icons/$iconId'])
			if (Paths.fileExists('images/$name.png', IMAGE)) return Paths.image(name, null, false);
		return null;
	}
}
