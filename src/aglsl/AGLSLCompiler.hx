package aglsl;

import flash.display3D.Context3DProgramType;
import flash.utils.ByteArray;
import flash.errors.Error;

import aglsl.AGALTokenizer;
import aglsl.AGLSLParser;
import aglsl.Description;
import aglsl.assembler.AGALMiniAssembler;

class AGLSLCompiler
{
	
	public var glsl:String;
	
	public function compile( programType:Context3DProgramType, source:String ):String
	{
		var agalMiniAssembler: AGALMiniAssembler = new AGALMiniAssembler();
		var tokenizer:AGALTokenizer = new AGALTokenizer();
		
		var data:ByteArray = new ByteArray();
		var concatSource:String;
		switch( programType )
		{
			case Context3DProgramType.VERTEX:
				concatSource = "part vertex 1\n" + source+ "endpart";
				agalMiniAssembler.assemble( concatSource );
				data = agalMiniAssembler.r.get("vertex").data;
			case Context3DProgramType.FRAGMENT:
				concatSource = "part fragment 1\n" + source + "endpart";
				agalMiniAssembler.assemble( concatSource );
				data = agalMiniAssembler.r.get("fragment").data;
		}
		var description:Description = tokenizer.decribeAGALByteArray( data );
		
		var parser:AGLSLParser = new AGLSLParser();
		this.glsl = parser.parse( description );
		
		return this.glsl;
	}

	public function new() {}
}
