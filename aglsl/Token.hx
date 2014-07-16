package aglsl;

class Token {

	public var dest : Destination;
	public var opcode : Int;
	public var a : Destination;
	public var b : Destination;
	public function new() {
		dest = new Destination();
		opcode = 0;
		a = new Destination();
		b = new Destination();
	}

}

