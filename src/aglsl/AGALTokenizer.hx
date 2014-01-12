package aglsl;

import flash.utils.ByteArray;

import aglsl.Header;
import aglsl.Description;
import aglsl.Token;

class AGALTokenizer
{
	public function new()
	{
	}
	
	public function decribeAGALByteArray( bytes: ByteArray ) : Description
	{
		var header:Header = new Header();
		if ( bytes.readUnsignedByte() != 0xa0 )
		{
			throw "Bad AGAL: Missing 0xa0 magic byte.";
		}
		
		header.version = bytes.readUnsignedInt();
		if ( header.version >= 0x10 )
		{
			bytes.readUnsignedByte();
			header.version >>= 1; 
		}

		if ( bytes.readUnsignedByte() != 0xa1 )
		{
			throw "Bad AGAL: Missing 0xa1 magic byte.";
		}
		
		header.progid = bytes.readUnsignedByte ( );
		switch ( header.progid ) {
			case 1:  header.type = "fragment";
			case 0:  header.type = "vertex";
			case 2:  header.type = "cpu";
			default: header.type = "";
		}
		
		var desc:Description = new Description();
		var tokens:Array<Token> = [];
		while ( bytes.position < bytes.length )
		{
			var token:aglsl.Token = new aglsl.Token();
			
			token.opcode = bytes.readUnsignedInt();          
			var lutentry = Mapping.agal2glsllut[token.opcode];
			if ( lutentry == null )
			{
				throw "Opcode not valid or not implemented yet: " + token.opcode;
			}

			if ( lutentry.matrixheight > 0 )
			{
				desc.hasmatrix = true;
			}

			if ( lutentry.dest )
			{
				token.dest.regnum = bytes.readUnsignedShort();
				token.dest.mask = bytes.readUnsignedByte();
				token.dest.regtype = bytes.readUnsignedByte();                        
				desc.regwrite[token.dest.regtype][token.dest.regnum] |= token.dest.mask;
			}
			else
			{
				token.dest = null; 
				bytes.readUnsignedInt(); 
			}                    

			if ( lutentry.a )
			{
				this.readReg( token.a, 1, desc, bytes );
			}
			else
			{
				token.a = null;
				bytes.readUnsignedInt(); 
				bytes.readUnsignedInt();                         
			}

			if ( lutentry.b )
			{
				this.readReg ( token.b, lutentry.matrixheight|0, desc, bytes );
			}
			else
			{
				token.b = null;
				bytes.readUnsignedInt(); 
				bytes.readUnsignedInt(); 
			}
			tokens.push( token );                                  
		}               
		desc.header = header;
		desc.tokens = tokens;
		
		return desc;
	}
	
	public function readReg( s:Dynamic, mh:UInt, desc:Description, bytes:ByteArray )
	{
		s.regnum = bytes.readUnsignedShort();
		s.indexoffset = bytes.readUnsignedByte(); 
		s.swizzle = bytes.readUnsignedByte(); 
		s.regtype = bytes.readUnsignedByte();                         

		desc.regread[s.regtype][s.regnum] = 0xf; // sould be swizzle to mask? should be |=                                                 
		if ( s.regtype == 0x5 )
		{ 
			// sampler
			s.lodbiad = s.indexoffset;
			s.indexoffset = null;
			s.swizzle = null;
			
			// sampler 
			s.readmode = bytes.readUnsignedByte(); 
			s.dim = s.readmode >> 4;
			s.readmode &= 0xf; 
			s.special = bytes.readUnsignedByte(); 
			s.wrap = s.special >> 4;
			s.special &= 0xf;        
			s.mipmap = bytes.readUnsignedByte(); 
			s.filter = s.mipmap >> 4;
			s.mipmap &= 0xf;                           

			desc.samplers[s.regnum] = s; 
		}
		else
		{
			s.indexregtype = bytes.readUnsignedByte(); 
			s.indexselect = bytes.readUnsignedByte(); 
			s.indirectflag = bytes.readUnsignedByte();                                              
		}           

		if ( s.indirectflag )
		{
			desc.hasindirect = true;
		}

		if ( !s.indirectflag && mh>0 )
		{
			var mhi:UInt;
			for ( mhi in 0...mh) //TODO wrong, should be |=
			{
				desc.regread[s.regtype][s.regnum+mhi] = desc.regread[s.regtype][s.regnum];
			}
		}
	}		
}

