package aglsl.assembler;
 import haxe.ds.StringMap.StringMap;
class OpcodeMap {
	static public var map(get_map, never) :StringMap<Opcode>;

	static var _map : StringMap<Opcode>;
	static public function get_map() : StringMap<Opcode> {
		if(OpcodeMap._map==null)  {
			OpcodeMap._map = new StringMap<Opcode>();
			OpcodeMap._map.set("mov", new Opcode("vector", "vector", 4, "none", 0, 0x00, true, null, null, null));
			OpcodeMap._map.set("add", new Opcode("vector", "vector", 4, "vector", 4, 0x01, true, null, null, null));
			OpcodeMap._map.set("sub", new Opcode("vector", "vector", 4, "vector", 4, 0x02, true, null, null, null));
			OpcodeMap._map.set("mul", new Opcode("vector", "vector", 4, "vector", 4, 0x03, true, null, null, null));
			OpcodeMap._map.set("div", new Opcode("vector", "vector", 4, "vector", 4, 0x04, true, null, null, null));
			OpcodeMap._map.set("rcp", new Opcode("vector", "vector", 4, "none", 0, 0x05, true, null, null, null));
			OpcodeMap._map.set("min", new Opcode("vector", "vector", 4, "vector", 4, 0x06, true, null, null, null));
			OpcodeMap._map.set("max", new Opcode("vector", "vector", 4, "vector", 4, 0x07, true, null, null, null));
			OpcodeMap._map.set("frc", new Opcode("vector", "vector", 4, "none", 0, 0x08, true, null, null, null));
			OpcodeMap._map.set("sqt", new Opcode("vector", "vector", 4, "none", 0, 0x09, true, null, null, null));
			OpcodeMap._map.set("rsq", new Opcode("vector", "vector", 4, "none", 0, 0x0a, true, null, null, null));
			OpcodeMap._map.set("pow", new Opcode("vector", "vector", 4, "vector", 4, 0x0b, true, null, null, null));
			OpcodeMap._map.set("log", new Opcode("vector", "vector", 4, "none", 0, 0x0c, true, null, null, null));
			OpcodeMap._map.set("exp", new Opcode("vector", "vector", 4, "none", 0, 0x0d, true, null, null, null));
			OpcodeMap._map.set("nrm", new Opcode("vector", "vector", 4, "none", 0, 0x0e, true, null, null, null));
			OpcodeMap._map.set("sin", new Opcode("vector", "vector", 4, "none", 0, 0x0f, true, null, null, null));
			OpcodeMap._map.set("cos", new Opcode("vector", "vector", 4, "none", 0, 0x10, true, null, null, null));
			OpcodeMap._map.set("crs", new Opcode("vector", "vector", 4, "vector", 4, 0x11, true, true, null, null));
			OpcodeMap._map.set("dp3", new Opcode("vector", "vector", 4, "vector", 4, 0x12, true, true, null, null));
			OpcodeMap._map.set("dp4", new Opcode("vector", "vector", 4, "vector", 4, 0x13, true, true, null, null));
			OpcodeMap._map.set("abs", new Opcode("vector", "vector", 4, "none", 0, 0x14, true, null, null, null));
			OpcodeMap._map.set("neg", new Opcode("vector", "vector", 4, "none", 0, 0x15, true, null, null, null));
			OpcodeMap._map.set("sat", new Opcode("vector", "vector", 4, "none", 0, 0x16, true, null, null, null));
			OpcodeMap._map.set("ted", new Opcode("vector", "vector", 4, "sampler", 1, 0x26, true, null, true, null));
			OpcodeMap._map.set("kil", new Opcode("none", "scalar", 1, "none", 0, 0x27, true, null, true, null));
			OpcodeMap._map.set("tex", new Opcode("vector", "vector", 4, "sampler", 1, 0x28, true, null, true, null));
			OpcodeMap._map.set("m33", new Opcode("vector", "matrix", 3, "vector", 3, 0x17, true, null, null, true));
			OpcodeMap._map.set("m44", new Opcode("vector", "matrix", 4, "vector", 4, 0x18, true, null, null, true));
			OpcodeMap._map.set("m43", new Opcode("vector", "matrix", 3, "vector", 4, 0x19, true, null, null, true));
			OpcodeMap._map.set("sge", new Opcode("vector", "vector", 4, "vector", 4, 0x29, true, null, null, null));
			OpcodeMap._map.set("slt", new Opcode("vector", "vector", 4, "vector", 4, 0x2a, true, null, null, null));
			OpcodeMap._map.set("sgn", new Opcode("vector", "vector", 4, "vector", 4, 0x2b, true, null, null, null));
			OpcodeMap._map.set("seq", new Opcode("vector", "vector", 4, "vector", 4, 0x2c, true, null, null, null));
			OpcodeMap._map.set("sne", new Opcode("vector", "vector", 4, "vector", 4, 0x2d, true, null, null, null));
		}
		return OpcodeMap._map;
	}

	public function new() {
	}

}

