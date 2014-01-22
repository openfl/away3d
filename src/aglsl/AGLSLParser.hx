package aglsl;

import aglsl.Description;
import flash.errors.Error;

class AGLSLParser
{
	public function new() {}

	public function parse( desc:Description ) : String
	{
		
		var header:String = "";
		var body:String = "";
		
		#if html5
        header += "precision highp float;\n";
		#end
		var tag = desc.header.type.charAt(0);
		
		#if html5
		declare uniforms
		if ( desc.header.type == "vertex" )
		{
		 	header += "uniform float yflip;\n";
		}
		#end
		if ( !desc.hasindirect )
		{
			var i:UInt;
			for ( i in 0...desc.regread[0x1].length )
			{
				if ( desc.regread[0x1][i] )
				{
					header += "uniform vec4 " + tag + "c" + i + ";\n";
				}
			}
		}
		else
		{
			header += "uniform vec4 " + tag + "carrr[" + Context3D.maxvertexconstants + "];\n";                // use max const count instead                
		}
		
		// declare temps
		var i:UInt;
		var len:UInt = desc.regread[0x2].length != 0 ? desc.regread[0x2].length : desc.regwrite[0x2].length;
		for ( i in 0...len )
		{
			if ( desc.regread[0x2][i]!=null || desc.regwrite[0x2][i]!=null ) // duh, have to check write only also... 
			{
				header += "vec4 " + tag + "t" + i + ";\n";
			}
		}
		
		// declare streams
		for ( i in 0...desc.regread[0x0].length )
		{
			if ( desc.regread[0x0][i] )
			{
				header += "attribute vec4 va" + i + ";\n";
			}
		}
		
		// declare interpolated
		len = desc.regread[0x4].length != 0 ? desc.regread[0x4].length : desc.regwrite[0x4].length;
		for ( i in 0...len)
		{
			if ( desc.regread[0x4][i] || desc.regwrite[0x4][i] )
			{
				header += "varying vec4 vi" + i + ";\n";
			}
		}
		
		// declare samplers
		var samptype:Array<String> = ["2D", "Cube", "3D", ""]; 
		for ( i in 0...desc.samplers.length)
		{
			if ( desc.samplers[i]!=null )
			{
				header += "uniform sampler" + samptype[ desc.samplers[i].dim&3 ] + " fs" + i + ";\n";
			}
		}
		
		// extra gl fluff: setup position and depth adjust temps
		if ( desc.header.type == "vertex" )
		{
			header += "vec4 outpos;\n";
		}
		if ( desc.writedepth )
		{
			header += "vec4 tmp_FragDepth;\n";
		}
		//if ( desc.hasmatrix ) 
		//    header += "vec4 tmp_matrix;\n";
		
		// start body of code
		body += "void main() {\n";
		
		for ( i in 0...desc.tokens.length )
		{
			var lutentry = Mapping.agal2glsllut[desc.tokens[i].opcode];
			if ( lutentry==null )
			{
				throw new Error("Opcode not valid or not implemented yet: "); /*+token.opcode;*/
			}
			var sublines = lutentry.matrixheight!=0 ? lutentry.matrixheight : 1;
			
			var sl:UInt;
			for ( sl in 0...sublines )
			{
				var line:String = "  " + lutentry.s;
				if ( desc.tokens[i].dest!=null )
				{
					var destregstring:String = "";
					var destcaststring:String = "";
					var destmaskstring:String = "";
					if ( lutentry.matrixheight>0)
					{
						if ( ((desc.tokens[i].dest.mask>>sl)&1)!=1 )
						{
							continue;
						}
						destregstring = this.regtostring( desc.tokens[i].dest.regtype, desc.tokens[i].dest.regnum, desc, tag );
						destcaststring = "float"; 
						destmaskstring = ["x","y","z","w"][sl];           
						destregstring += "." + destmaskstring;
					}
					else
					{
						destregstring = this.regtostring( desc.tokens[i].dest.regtype, desc.tokens[i].dest.regnum, desc, tag );
						if ( desc.tokens[i].dest.mask != 0xf )
						{
							var ndest:UInt = 0;
							destmaskstring = "";
							if ( desc.tokens[i].dest.mask & 1 != 0 )
							{
								ndest++;
								destmaskstring += "x";
							}
							if ( desc.tokens[i].dest.mask & 2 != 0  )
							{
								ndest++;
								destmaskstring += "y";
							}
							if ( desc.tokens[i].dest.mask & 4 != 0 )
							{
								ndest++;
								destmaskstring += "z";
							}
							if ( desc.tokens[i].dest.mask & 8 != 0 )
							{
								ndest++;
								destmaskstring += "w";
							}
							destregstring += "." + destmaskstring;
							switch( ndest )
							{
								case 1: destcaststring = "float";
								case 2: destcaststring = "vec2";
								case 3: destcaststring = "vec3";
								default: throw "Unexpected destination mask";
							}
						}
						else
						{
							destcaststring = "vec4";
							destmaskstring = "xyzw";
						}
					}
					line = StringTools.replace(line, "%dest", destregstring );
					line = StringTools.replace(line, "%cast", destcaststring );
					line = StringTools.replace(line, "%dm", destmaskstring );
				}
				var dwm:UInt = 0xf;
				if ( !lutentry.ndwm && lutentry.dest && desc.tokens[i].dest!=null )
				{
					dwm = desc.tokens[i].dest.mask;
				}
				if ( desc.tokens[i].a!=null )
				{
					line = StringTools.replace(line, "%a", this.sourcetostring( desc.tokens[i].a, 0, dwm, lutentry.scalar, desc, tag ) );
				}
				if ( desc.tokens[i].b!=null )
				{
					line = StringTools.replace(line, "%b", this.sourcetostring( desc.tokens[i].b, sl, dwm, lutentry.scalar, desc, tag ) );                                                                                
					if ( desc.tokens[i].b.regtype == 0x5 )
					{
						// sampler dim
						var texdim = ["2D","Cube","3D"][desc.tokens[i].b.dim];
						var texsize = ["vec2","vec3","vec3"][desc.tokens[i].b.dim];
						line = StringTools.replace(line, "%texdim", texdim );
						line = StringTools.replace(line, "%texsize", texsize );
						var texlod:String = "";
						line = StringTools.replace(line, "%lod", texlod );
					}
				}
				body += line;
			}
		}
		
		// adjust z from opengl range of -1..1 to 0..1 as in d3d, this also enforces a left handed coordinate system
		if ( desc.header.type == "vertex" )
		{
			#if html5
			body += "  gl_Position = vec4(outpos.x, yflip*outpos.y, outpos.z*2.0 - outpos.w, outpos.w);\n";
			#else
			body += "  gl_Position = vec4(outpos.x, outpos.y, outpos.z*2.0 - outpos.w, outpos.w);\n";
			#end
		}
		
		// clamp fragment depth
		if ( desc.writedepth )
		{
			body += "  gl_FragDepth = clamp(tmp_FragDepth,0.0,1.0);\n";
		}
		
		// close main
		body += "}\n";
		
		return header + body;
	}
	
	public function regtostring( regtype:UInt, regnum:UInt, desc:Description, tag:String ):String
	{
		switch ( regtype )
		{
			case 0x0: return "va" + regnum;
			case 0x1:
				if ( desc.hasindirect && desc.header.type == "vertex" )
				{
					return "vcarrr[" + regnum + "]";
				}
				else
				{
					return tag + "c" + regnum;
				}
			case 0x2: return tag + "t" + regnum;
			case 0x3: return desc.header.type == "vertex" ? "outpos" : "gl_FragColor";
			case 0x4: return "vi" + regnum;
			case 0x5: return "fs" + regnum;
			case 0x6: return "tmp_FragDepth";
			default: throw "Unknown register type";
		}
	}
	
	public function sourcetostring(s:Dynamic ,subline ,dwm,isscalar, desc, tag ):String
	{
		var swiz = [ "x","y","z","w" ]; 
		var r;
		
		if ( s.indirectflag ) {                                    
			r = "vcarrr[int("+this.regtostring(s.indexregtype, s.regnum, desc, tag)+"."+swiz[s.indexselect]+")";
			var realofs = subline+s.indexoffset;            
			if ( realofs<0 ) r+=Std.string(realofs);
			if ( realofs>0 ) r+="+"+Std.string(realofs);            
			r += "]";            
		}
		else
		{
			r = this.regtostring(s.regtype, s.regnum+subline, desc, tag);
		}
		
		// samplers never add swizzle        
		if ( s.regtype==0x5 )
		{
			return r;
		}
		
		// scalar, first component only
		if ( isscalar ) 
		{
			return r + "." + swiz[(s.swizzle>>0)&3];
		}
		
		// identity
        if ( s.swizzle == 0xe4 && dwm == 0xf )
		{
			return r;
		}
		
		// with destination write mask folded in
		r += ".";
		if ( dwm&1 != 0 ) r += swiz[(s.swizzle>>0)&3]; 
		if ( dwm&2 != 0 ) r += swiz[(s.swizzle>>2)&3]; 
		if ( dwm&4 != 0 ) r += swiz[(s.swizzle>>4)&3]; 
		if ( dwm&8 != 0 ) r += swiz[(s.swizzle>>6)&3]; 
		return r; 
	}
}
