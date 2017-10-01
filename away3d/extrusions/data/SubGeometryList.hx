package away3d.extrusions.data;

import away3d.materials.MaterialBase;
import away3d.core.base.SubGeometry;

import openfl.Vector;

class SubGeometryList
{
	public var id:Int;
	public var uvs:Vector<Float>;
	public var vertices:Vector<Float>;
	public var normals:Vector<Float>;
	public var indices:Vector<UInt>;
	public var subGeometry:SubGeometry;
	public var material:MaterialBase;
	
	public function new() {}
}