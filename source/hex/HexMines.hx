package hex;

import objects.Note;
import states.PlayState;

/**
 * VS Hex's StepMania-style mines (port of kade.hex.notes.MineReg / MineSlasher).
 * A mine is never hit or missed: it explodes if its column is held when it reaches the strumline.
 * Regular mines cost 1000 score and count as a miss; Slasher's mines (Headbasher) kill you.
 */
class HexMines
{
	static inline var MINE_WINDOW:Float = 75;
	static inline var HIT_WINDOW:Float = 160;
	static inline var STALE_MS:Float = -1000;

	var game:PlayState;
	var tapDur:Array<Float> = [0, 0, 0, 0];
	var explosions:Array<FlxSprite> = [];
	var pool:Array<FlxSprite> = [];
	var thrown:Array<Note> = [];

	public static function isMine(note:Note):Bool
		return note != null && isMineKind(note.noteType);

	public static function isMineKind(kind:String):Bool
		return kind == 'mine_reg' || kind == 'mine_slasher' || kind == 'mine';

	static function styleFor(kind:String):String
	{
		return switch (kind)
		{
			case 'mine_reg': 'hex_mine_reg';
			case 'mine_slasher': 'slasher_hb_1';
			default: 'hex_mines';
		}
	}

	/** Gives a mine note its Hex sprite. */
	public static function styleNote(note:Note, kind:String):Void
	{
		var style:HexNoteStyle = HexNoteStyle.loadNotesOnly(styleFor(kind));
		if (style == null) return;
		if (note.isSustainNote)
		{
			// mines don't have holds
			note.visible = false;
			note.alpha = 0;
			return;
		}
		note.rgbShader.enabled = false;
		note.frames = style.noteFrames();
		var anim:String = 'mine' + note.noteData;
		note.animation.addByPrefix(anim, style.notePrefix(note.noteData), style.noteFrameRate(note.noteData), true);
		note.scale.set(style.noteScale, style.noteScale);
		note.animation.play(anim, true);
		note.updateHitbox();
		note.centerOffsets();
		note.centerOrigin();
		// desync looping mines like Hex does
		if (note.animation.curAnim != null && note.animation.curAnim.numFrames > 1)
			note.animation.curAnim.curFrame = Std.int(Math.abs(note.strumTime * 10)) % note.animation.curAnim.numFrames;
	}

	public static function songHasMines(game:PlayState):Bool
	{
		for (note in game.unspawnNotes)
			if (isMine(note)) return true;
		return false;
	}

	public function new(game:PlayState)
	{
		this.game = game;
		// precache
		HexAssets.atlas('ui/hex/hex_mine_explosion');
		HexAssets.sound('ui/hex/sounds/mine_reg_hit');
	}

	public function update(elapsed:Float, held:Array<Bool>):Void
	{
		sweep();

		for (i in 0...4)
		{
			if (held[i]) tapDur[i] += elapsed * 1000;
			else tapDur[i] = 0;
		}

		var pos:Float = Conductor.songPosition;
		var dead:Array<Note> = null;
		for (mine in game.notes.members)
		{
			if (mine == null || !mine.alive || !isMine(mine) || mine.isSustainNote) continue;

			var diff:Float = mine.strumTime - pos;
			if (diff < STALE_MS)
			{
				if (dead == null) dead = [];
				dead.push(mine);
				continue;
			}
			if (!mine.visible || diff > 0) continue;

			if (mine.noteType == 'mine_slasher' && !thrown.contains(mine))
			{
				thrown.push(mine);
				throwMine(mine);
			}

			if (!mine.mustPress || game.cpuControlled) continue;

			var dir:Int = mine.noteData % 4;
			var startRange:Float = -MINE_WINDOW;
			for (other in game.notes.members)
			{
				if (other == null || other == mine || !other.alive || other.wasGoodHit || isMine(other) || other.isSustainNote) continue;
				if (!other.mustPress || other.noteData % 4 != dir) continue;
				var gap:Float = other.strumTime - mine.strumTime;
				if (Math.abs(gap) > HIT_WINDOW + MINE_WINDOW) continue;
				if (gap > 0)
					startRange = Math.max(startRange, -gap * 0.5);
				else
				{
					var apart:Float = -gap;
					startRange = Math.max(startRange, -Math.min(apart / 2, apart - tapDur[dir]));
				}
			}

			if (diff < startRange || !held[dir]) continue;
			explode(mine);
		}

		if (dead != null)
			for (mine in dead)
				removeNote(mine);
	}

	function removeNote(note:Note):Void
	{
		thrown.remove(note);
		game.invalidateNote(note);
	}

	/** Slasher throws his mines: he sings as they reach the strumline. */
	function throwMine(mine:Note):Void
	{
		var slasher = game.dad;
		if (slasher == null) return;
		var anims:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
		slasher.playAnim(anims[mine.noteData % 4], true);
		slasher.holdTimer = 0;
	}

	function explode(mine:Note):Void
	{
		var slasher:Bool = mine.noteType == 'mine_slasher';
		var x:Float = mine.x + mine.width / 2;
		var y:Float = mine.y + mine.height / 2;
		removeNote(mine);

		if (!slasher)
		{
			var snd = HexAssets.sound('ui/hex/sounds/mine_reg_hit');
			if (snd != null) FlxG.sound.play(snd);
		}

		var boom:FlxSprite = pool.pop();
		if (boom == null)
		{
			boom = new FlxSprite();
			boom.frames = HexAssets.atlas('ui/hex/hex_mine_explosion');
			boom.animation.addByPrefix('explode', 'mineBoom', 24, false);
			boom.antialiasing = ClientPrefs.data.antialiasing;
			boom.camera = game.camHUD;
		}
		else boom.revive();
		boom.animation.play('explode', true);
		boom.updateHitbox();
		boom.setPosition(x - boom.width / 2, y - boom.height / 2);
		explosions.push(boom);
		game.add(boom);

		if (slasher)
		{
			if (game.hexHud != null) game.hexHud.goEvil = true;
			if (!game.practiceMode) game.health = -1;
			return;
		}

		game.songScore -= 1000;
		game.songMisses++;
		game.health -= 0.1 * (ClientPrefs.data.gameplaySettings.exists('healthloss') ? ClientPrefs.data.gameplaySettings.get('healthloss') : 1);
		game.combo = 0;
		game.RecalculateRating(true);
	}

	function sweep():Void
	{
		var i:Int = explosions.length;
		while (i-- > 0)
		{
			var boom:FlxSprite = explosions[i];
			if (boom.animation.curAnim != null && !boom.animation.finished) continue;
			game.remove(boom, true);
			boom.kill();
			explosions.splice(i, 1);
			pool.push(boom);
		}
	}

	public function destroy():Void
	{
		for (boom in explosions.concat(pool))
			boom.destroy();
		explosions = pool = null;
		thrown = null;
		game = null;
	}
}
