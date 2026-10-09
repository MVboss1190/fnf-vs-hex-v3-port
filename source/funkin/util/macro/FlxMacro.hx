package funkin.util.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * Adds the fields V-Slice's Flixel has to Psych's Flixel, for the code ported from VS Hex
 * (same approach as Friday Night Funkin's own FlxMacro).
 */
class FlxMacro
{
	public static macro function buildFlxSprite():Array<Field>
	{
		return addFields([
			{name: 'localX', type: macro :Float, value: macro 0},
			{name: 'localY', type: macro :Float, value: macro 0},
			{name: 'localAngle', type: macro :Float, value: macro 0},
			{name: 'localScale', type: macro :flixel.math.FlxPoint, value: macro new flixel.math.FlxPoint(1, 1)},
			{name: 'localAlpha', type: macro :Float, value: macro 1},
			{name: 'localVisible', type: macro :Bool, value: macro true}
		]);
	}

	public static macro function buildFlxBasic():Array<Field>
	{
		return addFields([
			{name: 'zIndex', type: macro :Int, value: macro 0},
			{name: 'container', type: macro :Dynamic, value: macro null}
		]);
	}

	static function addFields(toAdd:Array<{name:String, type:ComplexType, value:Expr}>):Array<Field>
	{
		var pos:Position = Context.currentPos();
		var fields:Array<Field> = Context.getBuildFields();
		var owned:Array<String> = [for (f in fields) f.name];
		for (f in toAdd)
		{
			if (owned.contains(f.name)) continue;
			fields.push({
				name: f.name,
				access: [APublic],
				kind: FVar(f.type, f.value),
				pos: pos
			});
		}
		return fields;
	}
}
#end
