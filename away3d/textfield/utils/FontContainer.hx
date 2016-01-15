package away3d.textfield.utils;

import openfl.Vector;

/**
 * ...
 * @author P.J.Shand
 * @author Thomas Byrne
 */
class FontContainer 
{
	private var fontSizes:Vector<FontSize> = new Vector<FontSize>();
	
	public function FontContainer() 
	{
		
	}
	
	private function addSize(fontSize:FontSize):FontSize 
	{
		fontSizes.push(fontSize);
		return fontSize;
	}
	
	public function best(size:Int):FontSize 
	{
		var best:FontSize = null;
		var lowestDif:Float = Math.POSITIVE_INFINITY;
		for (i in 0...fontSizes.length) 
		{
			var fontSize:FontSize = fontSizes[i];
			var dif:Int = cast Math.abs(fontSize.size - size);
			if (dif < lowestDif) {
				best = fontSize;
				lowestDif = dif;
			}
		}
		return best;
	}	
}