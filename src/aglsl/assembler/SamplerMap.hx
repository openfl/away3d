package aglsl.assembler;

import haxe.ds.StringMap;

class Sampler
{
	public var shift:UInt;
	public var mask:UInt;
	public var value:UInt;
	
	public function new( shift:UInt, mask:UInt, value:UInt )
	{
		this.shift = shift;
		this.mask = mask;
		this.value = value;
	}
}

class SamplerMap
{

    private static var _map : StringMap<Sampler>;

    public static var map(get, null) : StringMap<Sampler>;
    public static function get_map() : StringMap<Sampler>
    {

        if ( SamplerMap._map==null )
        {

            SamplerMap._map = new StringMap<Sampler>();
            SamplerMap._map.set('rgba', new aglsl.assembler.Sampler( 8, 0xf, 0 ));
            SamplerMap._map.set('rg', new aglsl.assembler.Sampler( 8, 0xf, 5 ));
            SamplerMap._map.set('r', new aglsl.assembler.Sampler( 8, 0xf, 4 ));
            SamplerMap._map.set('compressed', new aglsl.assembler.Sampler( 8, 0xf, 1 ));
            SamplerMap._map.set('compressed_alpha', new aglsl.assembler.Sampler( 8, 0xf, 2 ));
            SamplerMap._map.set('dxt1', new aglsl.assembler.Sampler( 8, 0xf, 1 ));
            SamplerMap._map.set('dxt5', new aglsl.assembler.Sampler( 8, 0xf, 2 ));

            // dimension
            SamplerMap._map.set('2d', new aglsl.assembler.Sampler( 12, 0xf, 0 ));
            SamplerMap._map.set('cube', new aglsl.assembler.Sampler( 12, 0xf, 1 ));
            SamplerMap._map.set('3d', new aglsl.assembler.Sampler( 12, 0xf, 2 ));

            // special
            SamplerMap._map.set('centroid', new aglsl.assembler.Sampler( 16, 1, 1 ));
            SamplerMap._map.set('ignoresampler', new aglsl.assembler.Sampler( 16, 4, 4 ));

            // repeat
            SamplerMap._map.set('clamp', new aglsl.assembler.Sampler( 20, 0xf, 0 ));
            SamplerMap._map.set('repeat', new aglsl.assembler.Sampler( 20, 0xf, 1 ));
            SamplerMap._map.set('wrap', new aglsl.assembler.Sampler( 20, 0xf, 1 ));

            // mip
            SamplerMap._map.set('nomip', new aglsl.assembler.Sampler( 24, 0xf, 0 ));
            SamplerMap._map.set('mipnone', new aglsl.assembler.Sampler( 24, 0xf, 0 ));
            SamplerMap._map.set('mipnearest', new aglsl.assembler.Sampler( 24, 0xf, 1 ));
            SamplerMap._map.set('miplinear', new aglsl.assembler.Sampler( 24, 0xf, 2 ));

            // filter
            SamplerMap._map.set('nearest', new aglsl.assembler.Sampler( 28, 0xf, 0 ));
            SamplerMap._map.set('linear', new aglsl.assembler.Sampler( 28, 0xf, 1 ));
        }

        return SamplerMap._map;

    }

	public function new()
	{
	}
}


