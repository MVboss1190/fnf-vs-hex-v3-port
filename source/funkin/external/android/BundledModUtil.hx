package funkin.external.android;

#if android
/**
 * Extracts the mods packed inside the APK into the game's data folder on first launch.
 * See `funkin/util/BundledModUtil.java`.
 */
class BundledModUtil
{
  public static inline final STATE_IDLE:Int = 0;
  public static inline final STATE_RUNNING:Int = 1;
  public static inline final STATE_DONE:Int = 2;
  public static inline final STATE_FAILED:Int = 3;

  public static function needsExtraction():Bool
  {
    final fn:Null<Dynamic> = JNIUtil.createStaticMethod('funkin/util/BundledModUtil', 'needsExtraction', '()Z');
    return fn != null && fn();
  }

  public static function startExtraction():Void
  {
    final fn:Null<Dynamic> = JNIUtil.createStaticMethod('funkin/util/BundledModUtil', 'startExtraction', '()V');
    if (fn != null) fn();
  }

  public static function getState():Int
  {
    final fn:Null<Dynamic> = JNIUtil.createStaticMethod('funkin/util/BundledModUtil', 'getState', '()I');
    return fn != null ? fn() : STATE_FAILED;
  }

  public static function getProgress():Float
  {
    final fn:Null<Dynamic> = JNIUtil.createStaticMethod('funkin/util/BundledModUtil', 'getProgress', '()F');
    return fn != null ? fn() : 0.0;
  }

  public static function getError():String
  {
    final fn:Null<Dynamic> = JNIUtil.createStaticMethod('funkin/util/BundledModUtil', 'getError', '()Ljava/lang/String;');
    return fn != null ? Std.string(fn()) : 'JNI unavailable';
  }
}
#end
