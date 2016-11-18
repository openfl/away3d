package away3d.animators.data;

/**
 * A value object for a single frame of animation in a <code>UVClipNode</code> object.
 *
 * @see away3d.animators.nodes.UVClipNode
 */
class UVAnimationFrame
{
	/**
	 * The u-component offset of the UV animation frame.
	 */
	public var offsetU:Float;
	
	/**
	 * The v-component offset of the UV animation frame.
	 */
	public var offsetV:Float;
	
	/**
	 * The u-component scale of the UV animation frame.
	 */
	public var scaleU:Float;
	
	/**
	 * The v-component scale of the UV animation frame.
	 */
	public var scaleV:Float;
	
	/**
	 * The rotation value (in degrees) of the UV animation frame.
	 */
	public var rotation:Float;
	
	/**
	 * Creates a new <code>UVAnimationFrame</code> object.
	 *
	 * @param offsetU The u-component offset of the UV animation frame.
	 * @param offsetV The v-component offset of the UV animation frame.
	 * @param scaleU The u-component scale of the UV animation frame.
	 * @param scaleV The v-component scale of the UV animation frame.
	 * @param rotation The rotation value (in degrees) of the UV animation frame.
	 */
	public function new(offsetU:Float = 0, offsetV:Float = 0, scaleU:Float = 1, scaleV:Float = 1, rotation:Float = 0)
	{
		this.offsetU = offsetU;
		this.offsetV = offsetV;
		this.scaleU = scaleU;
		this.scaleV = scaleV;
		this.rotation = rotation;
	}
}