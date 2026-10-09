package kade.hex.menus;

import flixel.FlxSprite;
import flixel.animation.FlxAnimationController;

class Anim
{
  // Typed access: FlxAnimationController's fields are properties, which hxcpp can't reach through Dynamic.
  static inline function ctrl(spr:Dynamic):FlxAnimationController
  {
    var s:FlxSprite = cast spr;
    return s.animation;
  }

  public static function play(spr:Dynamic, name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void
  {
    ctrl(spr).play(name, force, reversed, frame);
  }

  public static function addByPrefix(spr:Dynamic, name:String, prefix:String, fps:Float = 24, looped:Bool = true):Void
  {
    ctrl(spr).addByPrefix(name, prefix, fps, looped);
  }

  public static function addByNames(spr:Dynamic, name:String, names:Array<String>, fps:Float = 24, looped:Bool = true):Void
  {
    ctrl(spr).addByNames(name, names, fps, looped);
  }

  public static function name(spr:Dynamic):String
  {
    return ctrl(spr).name;
  }

  public static function finished(spr:Dynamic):Bool
  {
    return ctrl(spr).finished;
  }

  public static function frameIndex(spr:Dynamic):Int
  {
    return ctrl(spr).frameIndex;
  }

  public static function finish(spr:Dynamic):Void
  {
    ctrl(spr).finish();
  }

  public static function has(spr:Dynamic, name:String):Bool
  {
    return ctrl(spr).getByName(name) != null;
  }

  public static function onFinish(spr:Dynamic, fn:String->Void):Void
  {
    // Flixel 5 has a single finish callback instead of a signal, so chain them.
    var c:FlxAnimationController = ctrl(spr);
    var prev:String->Void = c.finishCallback;
    c.finishCallback = function(n:String)
    {
      if (prev != null) prev(n);
      fn(n);
    };
  }
}
