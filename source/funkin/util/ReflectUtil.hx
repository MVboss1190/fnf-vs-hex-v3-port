package funkin.util;

class ReflectUtil
{
	public static function getInstanceFields(cls:Class<Dynamic>):Array<String>
		return Type.getInstanceFields(cls);
}
