package away3d.textfield;

import openfl.Vector;

/**
 * ...
 * @author P.J.Shand
 */
class CharLocation
{
	public var char:BitmapChar;
	public var scale:Float;
	public var x:Float;
	public var y:Float;
	
	public function new(char:BitmapChar)
	{
		reset(char);
	}

	private function reset(char:BitmapChar):CharLocation
	{
		this.char = char;
		return this;
	}

	public function getChar():BitmapChar {
		return char;
	}

	// pooling

   private static var sInstancePool = new Array<CharLocation>();
	private static var sVectorPool = new Array<Dynamic>();

	private static var sInstanceLoan = new Array<CharLocation>();
	private static var sVectorLoan = new Array<Dynamic>();

	public static function instanceFromPool(char:BitmapChar):CharLocation
	{
		var instance:CharLocation = sInstancePool.length > 0 ?
			sInstancePool.pop() : new CharLocation(char);

		instance.reset(char);
		sInstanceLoan[sInstanceLoan.length] = instance;

		return instance;
	}

	public static function vectorFromPool():Vector<CharLocation>
	{
		var vector:Vector<CharLocation> = sVectorPool.length > 0 ?
			sVectorPool.pop() : new Vector<CharLocation> ();

		vector.length = 0;
		sVectorLoan[sVectorLoan.length] = vector;

		return vector;
	}

	public static function rechargePool():Void
	{
		var instance:CharLocation;
		var vector:Vector<CharLocation>;

		while (sInstanceLoan.length > 0)
		{
			instance = sInstanceLoan.pop();
			instance.char = null;
			sInstancePool[sInstancePool.length] = instance;
		}

		while (sVectorLoan.length > 0)
		{
			vector = sVectorLoan.pop();
			vector.length = 0;
			sVectorPool[sVectorPool.length] = vector;
		}
	}
}