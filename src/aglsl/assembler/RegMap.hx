package aglsl.assembler;

import haxe.ds.StringMap;

class Reg
{
	
	public var code:UInt;
	public var desc:String;
	
	public function new( code:UInt, desc:String )
	{
		this.code = code;
		this.desc = desc;
	}
}

class RegMap
{

    private static var _map:StringMap<Reg>;

    public static var map(get, null):StringMap<Reg>;
    public static function get_map () : StringMap<Reg>
    {

        if ( RegMap._map==null )
        {

            RegMap._map = new StringMap<Reg>();
            RegMap._map.set('va', new aglsl.assembler.Reg( 0x00, "vertex attribute" ));
            RegMap._map.set('fc', new aglsl.assembler.Reg( 0x01, "fragment constant" ));
            RegMap._map.set('vc', new aglsl.assembler.Reg( 0x01, "vertex constant" ));
            RegMap._map.set('ft', new aglsl.assembler.Reg( 0x02, "fragment temporary" ));
            RegMap._map.set('vt', new aglsl.assembler.Reg( 0x02, "vertex temporary" ));
            RegMap._map.set('vo', new aglsl.assembler.Reg( 0x03, "vertex output" ));
            RegMap._map.set('op', new aglsl.assembler.Reg( 0x03, "vertex output" ));
            RegMap._map.set('fd', new aglsl.assembler.Reg( 0x03, "fragment depth output" ));
            RegMap._map.set('fo', new aglsl.assembler.Reg( 0x03, "fragment output" ));
            RegMap._map.set('oc', new aglsl.assembler.Reg( 0x03, "fragment output" ));
            RegMap._map.set('v',  new aglsl.assembler.Reg( 0x04, "varying" ));
            RegMap._map.set('vi', new aglsl.assembler.Reg( 0x04, "varying output" ));
            RegMap._map.set('fi', new aglsl.assembler.Reg( 0x04, "varying input" ));
            RegMap._map.set('fs', new aglsl.assembler.Reg( 0x05, "sampler" ));


        }

        return RegMap._map;

    }

	public function new()
	{
	}
}