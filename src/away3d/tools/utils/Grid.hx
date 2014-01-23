/**
 * Class Grid snaps vertexes or meshes according to a given grid unit.<code>Grid</code>
 */
package away3d.tools.utils;


import flash.Vector;
import away3d.containers.ObjectContainer3D;
import away3d.core.base.Geometry;
import away3d.core.base.ISubGeometry;
import away3d.core.base.SubGeometry;
import away3d.entities.Mesh;

class Grid {
    public var unit(get_unit, set_unit):Float;
    public var objectSpace(get_objectSpace, set_objectSpace):Bool;

    private var _unit:Float;
    private var _objectSpace:Bool;
/**
	 *  Grid snaps vertexes according to a given grid unit
	 * @param     unit                        [optional] Number. The grid unit. Default is 1.
	 * @param     objectSpace            [optional] Boolean. Apply only to vertexes in geometry objectspace when Object3D are considered. Default is false.
	 */

    function new(unit:Float = 1, objectSpace:Bool = false) {
        _objectSpace = objectSpace;
        _unit = Math.abs(unit);
    }

/**
	 *  Apply the grid code to a given object3D. If type ObjectContainer3D, all children Mesh vertices will be affected.
	 * @param     object3d        Object3D. The Object3d to snap to grid.
	 * @param     dovert            [optional]. If the vertices must be handled or not. When false only object position is snapped to grid. Default is false.
	 */

    public function snapObject(object3d:ObjectContainer3D, dovert:Bool = false):Void {
        parse(object3d, dovert);
    }

/**
	 *  Snaps to grid a given Vector.&lt;Number&gt; of vertices
	 * @param     vertices        Vector.&lt;Number&gt;. The vertices vector
	 */

    public function snapVertices(vertices:Vector<Float>):Vector<Float> {
        var i:Int = 0;
        while (i < vertices.length) {
            vertices[i] -= vertices[i] % _unit;
            ++i;
        }
        return vertices;
    }

/**
	 *  Apply the grid code to a single mesh
	 * @param     mesh        Mesh. The mesh to snap to grid. Vertices are affected by default. Mesh position is snapped if grid.objectSpace is true;
	 */

    public function snapMesh(mesh:Mesh):Void {
        if (!_objectSpace) {
            mesh.scenePosition.x -= mesh.scenePosition.x % _unit;
            mesh.scenePosition.y -= mesh.scenePosition.y % _unit;
            mesh.scenePosition.z -= mesh.scenePosition.z % _unit;
        }
        snap(mesh);
    }

/**
	 * Defines if the grid unit.
	 */

    public function set_unit(val:Float):Float {
        _unit = Math.abs(val);
        _unit = ((_unit == 0)) ? .001 : _unit;
        return val;
    }

    public function get_unit():Float {
        return _unit;
    }

/**
	 * Defines if the grid unit is applied in objectspace or worldspace. In worldspace, objects positions are affected.
	 */

    public function set_objectSpace(b:Bool):Bool {
        _objectSpace = b;
        return b;
    }

    public function get_objectSpace():Bool {
        return _objectSpace;
    }

    private function parse(object3d:ObjectContainer3D, dovert:Bool = true):Void {
        var child:ObjectContainer3D;
        if (!_objectSpace) {
            object3d.scenePosition.x -= object3d.scenePosition.x % _unit;
            object3d.scenePosition.y -= object3d.scenePosition.y % _unit;
            object3d.scenePosition.z -= object3d.scenePosition.z % _unit;
        }
        if (Std.is(object3d, Mesh) && object3d.numChildren == 0 && dovert) snap(cast((object3d), Mesh));
        var i:Int = 0;
        while (i < object3d.numChildren) {
            child = object3d.getChildAt(i);
            parse(child, dovert);
            ++i;
        }
    }

    private function snap(mesh:Mesh):Void {
        var geometry:Geometry = mesh.geometry;
        var geometries:Vector<ISubGeometry> = geometry.subGeometries;
        var numSubGeoms:Int = geometries.length;
        var vertices:Vector<Float>;
        var j:Int;
        var i:Int = 0;
        var vecLength:Int;
        var subGeom:SubGeometry;
        var stride:Int;
        i = 0;
        while (i < numSubGeoms) {
            subGeom = cast((geometries[i]), SubGeometry);
            vertices = subGeom.vertexData;
            vecLength = vertices.length;
            stride = subGeom.vertexStride;
            j = subGeom.vertexOffset;
            while (j < vecLength) {
                vertices[j] -= vertices[j] % _unit;
                vertices[j + 1] -= vertices[j + 1] % _unit;
                vertices[j + 2] -= vertices[j + 2] % _unit;
                j += stride;
            }
            subGeom.updateVertexData(vertices);
            ++i;
        }
    }

}

