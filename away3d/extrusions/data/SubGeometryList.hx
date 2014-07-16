package away3d.extrusions.data;

import away3d.materials.MaterialBase;
import away3d.core.base.SubGeometry;
class SubGeometryList {

    public var id:Int;
    public var uvs:Array<Float>;
    public var vertices:Array<Float>;
    public var normals:Array<Float>;
    public var indices:Array<UInt>;
    public var subGeometry:SubGeometry;
    public var material:MaterialBase;

    public function new() {}
}
