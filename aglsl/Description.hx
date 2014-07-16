
package aglsl;

class Description {

	public var regread : Array<Dynamic>;
	public var regwrite : Array<Dynamic>;
	public var hasindirect : Bool;
	public var writedepth : Bool;
	public var hasmatrix : Bool;
	public var samplers : Array<Dynamic>;
	// added due to dynamic assignment 3*0xFFFFFFuuuu
	public var tokens : Array<Dynamic>;
	public var header : Header;
	public function new() {
		regread = [[], [], [], [], [], [], []];
		regwrite = [[], [], [], [], [], [], []];
		hasindirect = false;
		writedepth = false;
		hasmatrix = false;
		samplers = [];
		//
		// added due to dynamic assignment 3*0xFFFFFFuuuu
		tokens = [];
		header = new Header();
	}

}

