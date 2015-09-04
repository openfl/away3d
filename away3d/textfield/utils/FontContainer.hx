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
		var best:FontSize;
		var lowestDif:Float = Math.POSITIVE_INFINITY;
		for (var i:int = 0; i < fontSizes.length; i++) 
		{
			var fontSize:FontSize = fontSizes[i];
			var dif:int = Math.abs(fontSize.size - size);
			if (dif < lowestDif) {
				best = fontSize;
				lowestDif = dif;
			}
		}
		return best;
	}	
}