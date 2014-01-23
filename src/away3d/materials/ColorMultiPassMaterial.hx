/**
 * ColorMultiPassMaterial is a multi-pass material that uses a flat color as the surface's diffuse reflection value.
 */
package away3d.materials;


class ColorMultiPassMaterial extends MultiPassMaterialBase {
    public var color(get_color, set_color):Int;

/**
	 * Creates a new ColorMultiPassMaterial object.
	 *
	 * @param color The material's diffuse surface color.
	 */

    public function new(color:Int = 0xcccccc) {
        super();
        this.color = color;
    }

/**
	 * The diffuse reflectivity color of the surface.
	 */

    public function get_color():Int {
        return diffuseMethod.diffuseColor;
    }

    public function set_color(value:Int):Int {
        diffuseMethod.diffuseColor = value;
        return value;
    }

}

