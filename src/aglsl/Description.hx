package aglsl;

import aglsl.Token;
import aglsl.Header;

class Description
{
	public var regread:Array<Array<Dynamic>>;// = [[],[],[],[],[],[],[]];
    public var regwrite:Array<Array<Dynamic>> ;//= [[],[],[],[],[],[],[]];
    public var hasindirect:Bool;
    public var writedepth:Bool;
    public var hasmatrix:Bool;
    public var samplers:Array<Dynamic>;
	
	// added due to dynamic assignment 3*0xFFFFFFuuuu
	public var tokens: Array<Token>;
	public var header: Header;
	
	public function new()
	{
		regread = [[],[],[],[],[],[],[]];
	    regwrite = [[],[],[],[],[],[],[]];
	    hasindirect =  false;
	    writedepth = false;
	    hasmatrix = false;
	    samplers = [];
		
		tokens = [];
		header = new Header();
	}
}