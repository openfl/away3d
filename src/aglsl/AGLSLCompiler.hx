
package aglsl; 
import aglsl.assembler.AGALMiniAssembler; 
import flash.utils.ByteArray;
class AGLSLCompiler {

	public var glsl : String;
	public function new() {  
	}

	public function compile(programType : String, source : String) : String {
		var agalMiniAssembler : AGALMiniAssembler = new AGALMiniAssembler();
		var tokenizer : AGALTokenizer = new AGALTokenizer();
		var data : ByteArray;
		var concatSource : String;
		switch(programType) {
		case "vertex":
			 {
				concatSource = "part vertex 1 \n" + source + "endpart";
				agalMiniAssembler.assemble(concatSource);
				data = agalMiniAssembler.r.get("vertex").data;
			}

		case "fragment":
			 {
				concatSource = "part fragment 1 \n" + source + "endpart";
				agalMiniAssembler.assemble(concatSource);
				data = agalMiniAssembler.r.get("fragment").data;
			}

		default:
			throw "Unknown Context3DProgramType";
		}
		var description : Description = tokenizer.decribeAGALByteArray(data);
		var parser : AGLSLParser = new AGLSLParser();
		this.glsl = parser.parse(description);
		return this.glsl;
	}

}

