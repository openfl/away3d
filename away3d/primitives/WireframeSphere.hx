package away3d.primitives;

import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * A WireframeSphere primitive mesh
 */
class WireframeSphere extends WireframePrimitiveBase
{
	private var _segmentsW:Int;
	private var _segmentsH:Int;
	private var _radius:Float;
	
	/**
	 * Creates a new WireframeSphere object.
	 * @param radius The radius of the sphere.
	 * @param segmentsW Defines the number of horizontal segments that make up the sphere.
	 * @param segmentsH Defines the number of vertical segments that make up the sphere.
	 * @param color The colour of the wireframe lines
	 * @param thickness The thickness of the wireframe lines
	 */
	public function new(radius:Float = 50, segmentsW:Int = 16, segmentsH:Int = 12, color:Int = 0xFFFFFF, thickness:Float = 1)
	{
		super(color, thickness);
		
		_radius = radius;
		_segmentsW = segmentsW;
		_segmentsH = segmentsH;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function buildGeometry():Void
	{
		var vertices:Vector<Float> = new Vector<Float>();
		var v0:Vector3D = new Vector3D();
		var v1:Vector3D = new Vector3D();
		var numVerts:Int = 0;
		var index:Int = 0;
		
		var horangle:Float, z:Float, ringradius:Float;
		var verangle:Float, x:Float, y:Float;
		
		for (j in 0...(_segmentsH + 1)) {
			horangle = Math.PI*j/_segmentsH;
			z = -_radius*Math.cos(horangle);
			ringradius = _radius*Math.sin(horangle);
			
			for (i in 0...(_segmentsW + 1)) {
				verangle = 2*Math.PI*i/_segmentsW;
				x = ringradius*Math.cos(verangle);
				y = ringradius*Math.sin(verangle);
				vertices[numVerts++] = x;
				vertices[numVerts++] = -z;
				vertices[numVerts++] = y;
			}
		}
		
		var a:Int, b:Int, c:Int, d:Int;
		
		for (j in 1...(_segmentsH + 1)) {
			for (i in 1...(_segmentsH + 1)) {
				a = ((_segmentsW + 1)*j + i)*3;
				b = ((_segmentsW + 1)*j + i - 1)*3;
				c = ((_segmentsW + 1)*(j - 1) + i - 1)*3;
				d = ((_segmentsW + 1)*(j - 1) + i)*3;
				
				if (j == _segmentsH) {
					v0.x = vertices[c];
					v0.y = vertices[c + 1];
					v0.z = vertices[c + 2];
					v1.x = vertices[d];
					v1.y = vertices[d + 1];
					v1.z = vertices[d + 2];
					updateOrAddSegment(index++, v0, v1);
					v0.x = vertices[a];
					v0.y = vertices[a + 1];
					v0.z = vertices[a + 2];
					updateOrAddSegment(index++, v0, v1);
				} else if (j == 1) {
					v1.x = vertices[b];
					v1.y = vertices[b + 1];
					v1.z = vertices[b + 2];
					v0.x = vertices[c];
					v0.y = vertices[c + 1];
					v0.z = vertices[c + 2];
					updateOrAddSegment(index++, v0, v1);
				} else {
					v1.x = vertices[b];
					v1.y = vertices[b + 1];
					v1.z = vertices[b + 2];
					v0.x = vertices[c];
					v0.y = vertices[c + 1];
					v0.z = vertices[c + 2];
					updateOrAddSegment(index++, v0, v1);
					v1.x = vertices[d];
					v1.y = vertices[d + 1];
					v1.z = vertices[d + 2];
					updateOrAddSegment(index++, v0, v1);
				}
			}
		}
	}
}