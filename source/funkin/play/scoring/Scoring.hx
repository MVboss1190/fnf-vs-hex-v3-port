package funkin.play.scoring;

import funkin.save.Save.SaveScoreData;
import funkin.save.Save.SaveScoreTallyData;

enum ScoringRank
{
	PERFECT_GOLD;
	PERFECT;
	EXCELLENT;
	GREAT;
	GOOD;
	SHIT;
}

/**
 * VS Hex compatibility: V-Slice's clear percentage and ranks.
 */
class Scoring
{
	public static function tallyCompletion(tallies:SaveScoreTallyData):Float
	{
		if (tallies == null || tallies.totalNotes <= 0) return 0.0;
		return Math.min(1.0, (tallies.sick + tallies.good) / tallies.totalNotes);
	}

	public static function calculateRank(scoreData:SaveScoreData):Null<ScoringRank>
	{
		if (scoreData == null || scoreData.tallies == null || scoreData.tallies.totalNotes <= 0) return null;
		var t:SaveScoreTallyData = scoreData.tallies;
		if (t.missed == 0 && t.bad == 0 && t.shit == 0 && t.good == 0 && t.sick >= t.totalNotes) return PERFECT_GOLD;
		var completion:Float = tallyCompletion(t);
		if (completion >= 1.0) return PERFECT;
		if (completion >= 0.9) return EXCELLENT;
		if (completion >= 0.8) return GREAT;
		if (completion >= 0.6) return GOOD;
		return SHIT;
	}
}
