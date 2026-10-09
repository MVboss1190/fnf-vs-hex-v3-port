package kade.hex.notefield;

import flixel.FlxG;
import funkin.play.PlayState;
#if FEATURE_TOUCH_CONTROLS
import funkin.mobile.input.ControlsHandler;
import funkin.mobile.ui.FunkinHitbox.FunkinHitboxControlSchemes;
#end

/**
 * Stand-in for the notefield's TouchLanes from Kade's unreleased modchart-engine.
 * Only built into the Android port when that mod isn't bundled.
 *
 * Hex turns lanes on for songs with extra strumlines (and for the "Four Lanes" option);
 * here that swaps the engine's touch hitbox to its full-screen four-lane scheme.
 */
class TouchLanes
{
  public static var enabled(default, null):Bool = false;

  static var applied:Bool = false;
  static var layoutCallbacks:Array<Void->Void> = [];
  static var layoutState:Dynamic = null;
  static var watching:Bool = false;

  /**
   * Callbacks and the lane state belong to one PlayState; start over when a new one shows up.
   */
  static function sync():Void
  {
    if (layoutState == PlayState.instance) return;
    layoutState = PlayState.instance;
    layoutCallbacks = [];
    enabled = false;
    applied = false;
  }

  public static function toggle(on:Bool, ?fromOption:Bool):Void
  {
    sync();
    enabled = on;
    apply();

    if (!watching)
    {
      // The hitbox may not exist yet (songs toggle lanes while loading), so keep checking each frame.
      watching = true;
      FlxG.signals.postUpdate.add(apply);
    }
  }

  public static function afterLayout(callback:Void->Void):Void
  {
    sync();
    if (callback != null && layoutCallbacks.indexOf(callback) == -1) layoutCallbacks.push(callback);
  }

  static function apply():Void
  {
    if (layoutState != PlayState.instance) sync();
    if (applied == enabled) return;

    #if FEATURE_TOUCH_CONTROLS
    var state:PlayState = PlayState.instance;
    if (state == null || state.hitbox == null) return;

    applied = enabled;
    if (!ControlsHandler.hasExternalInputDevice)
    {
      state.addHitbox(state.hitbox.visible, true, enabled ? FunkinHitboxControlSchemes.FourLanes : null);
    }
    #else
    applied = enabled;
    #end

    for (callback in layoutCallbacks)
    {
      if (callback != null) callback();
    }
  }
}
