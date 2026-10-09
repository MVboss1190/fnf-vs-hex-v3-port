package funkin.modding;

import funkin.util.macro.ClassMacro;

/**
 * VS Hex ships its menus, HUD modules and note kinds as compiled-script classes (`kade.hex.*`).
 * This port builds them into the game instead of loading `.cppia` files at runtime, so here they are
 * registered with Polymod exactly as if a compiled script had provided them: registries
 * (modules, songs, note kinds) list them and Hex's scripts import them as usual.
 */
class HexClasses
{
  public static final MOD_ID:String = 'hex';

  public static function register():Void
  {
    #if (hxcpp && POLYMOD_CPPIA)
    if (!PolymodHandler.loadedModIds.contains(MOD_ID))
    {
      trace('[HEX] Hex mod is not loaded, its built-in classes stay unregistered.');
      return;
    }

    var count:Int = 0;
    for (cls in ClassMacro.listClassesInPackage('kade.hex', true))
    {
      var name:Null<String> = Type.getClassName(cls);
      if (name == null) continue;
      @:privateAccess
      {
        polymod.hscript._internal.PolymodCppiaClassReference.registry.set(name, cls);
        polymod.hscript._internal.PolymodCppiaClassReference.everProvided.set(name, true);
        polymod.hscript._internal.PolymodCppiaClassReference.declared.set(name, cls);
      }
      count++;
    }
    trace('[HEX] Registered $count built-in Hex classes.');
    #end
  }
}
