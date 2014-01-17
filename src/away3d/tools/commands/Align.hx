/**
 * Class Aligns an arrays of Object3Ds, Vector3D's or Vertexes compaired to each other.<code>Align</code>
 */
package away3d.tools.commands;


import flash.errors.Error;
import flash.Vector;
import away3d.entities.Mesh;
import away3d.tools.utils.Bounds;

class Align {

    static public var X_AXIS:String = "x";
    static public var Y_AXIS:String = "y";
    static public var Z_AXIS:String = "z";
    static public var POSITIVE:String = "+";
    static public var NEGATIVE:String = "-";
    static public var AVERAGE:String = "av";
    static private var _axis:String;
    static private var _condition:String;
/**
	 * Aligns a series of meshes to their bounds along a given axis.
	 *
	 * @param     meshes        A Vector of Mesh objects
	 * @param     axis        Represent the axis to align on.
	 * @param     condition    Can be POSITIVE ('+') or NEGATIVE ('-'), Default is POSITIVE ('+')
	 */

    static public function alignMeshes(meshes:Vector<Mesh>, axis:String, condition:String = POSITIVE):Void {
        checkAxis(axis);
        checkCondition(condition);
        var base:Float;
        var bounds:Vector<MeshBound> = getMeshesBounds(meshes);
        var i:Int = 0;
        var prop:String = getProp();
        var mb:MeshBound;
        var m:Mesh;
        var val:Float;
        switch(_condition) {
            case POSITIVE:
                base = getMaxBounds(bounds);
                i = 0;
                while (i < meshes.length) {
                    m = meshes[i];
                    mb = bounds[i];
                    val = m[_axis];
                    val -= base - mb[prop] + m[_axis];
                    m[_axis] = -val;
                    bounds[i] = null;
                    ++i;
                }
            case NEGATIVE:
                base = getMinBounds(bounds);
                i = 0;
                while (i < meshes.length) {
                    m = meshes[i];
                    mb = bounds[i];
                    val = m[_axis];
                    val -= base + mb[prop] + m[_axis];
                    m[_axis] = -val;
                    bounds[i] = null;
                    ++i;
                }
        }
        bounds = null;
    }

/**
	 * Place one or more meshes at y 0 using their min bounds
	 */

    static public function alignToFloor(meshes:Vector<Mesh>):Void {
        if (meshes.length == 0) return;
        var i:Int = 0;
        while (i < meshes.length) {
            Bounds.getMeshBounds(meshes[i]);
            meshes[i].y = Bounds.minY + (Bounds.maxY - Bounds.minY);
            ++i;
        }
    }

/**
	 * Applies to array elements the alignment according to axis, x, y or z and a condition.
	 * each element must have public x,y and z  properties. In case elements are meshes only their positions is affected. Method doesn't take in account their respective bounds
	 * String condition:
	 * "+" align to highest value on a given axis
	 * "-" align to lowest value on a given axis
	 * "" align to a given axis on 0; This is the default.
	 * "av" align to average of all values on a given axis
	 *
	 * @param     aObjs        Array. An array with elements with x,y and z public properties such as Mesh, Object3D, ObjectContainer3D,Vector3D or Vertex
	 * @param     axis            String. Represent the axis to align on.
	 * @param     condition    [optional]. String. Can be '+", "-", "av" or "", Default is "", aligns to given axis at 0.
	 */

    static public function align(aObjs:Array<Dynamic>, axis:String, condition:String = ""):Void {
        checkAxis(axis);
        checkCondition(condition);
        var base:Float;
        switch(_condition) {
            case POSITIVE:
                base = getMax(aObjs, _axis);
            case NEGATIVE:
                base = getMin(aObjs, _axis);
            case AVERAGE:
                base = getAverage(aObjs, _axis);
            case "":
                base = 0;
        }
        var i:Int = 0;
        while (i < aObjs.length) {
            aObjs[i][_axis] = base;
            ++i;
        }
    }

/**
	 * Applies to array elements a distributed alignment according to axis, x,y or z. In case elements are meshes only their positions is affected. Method doesn't take in account their respective bounds
	 * each element must have public x,y and z  properties
	 * @param     aObjs        Array. An array with elements with x,y and z public properties such as Mesh, Object3D, ObjectContainer3D,Vector3D or Vertex
	 * @param     axis            String. Represent the axis to align on.
	 */

    static public function distribute(aObjs:Array<Dynamic>, axis:String):Void {
        checkAxis(axis);
        var max:Float = getMax(aObjs, _axis);
        var min:Float = getMin(aObjs, _axis);
        var unit:Float = (max - min) / aObjs.length;
        aObjs.sortOn(axis, 16);
        var step:Float = 0;
        var i:Int = 0;
        while (i < aObjs.length) {
            aObjs[i][_axis] = min + step;
            step += unit;
            ++i;
        }
    }

    static private function checkAxis(axis:String):Void {
        axis = axis.substring(0, 1).toLowerCase();
        if (axis == X_AXIS || axis == Y_AXIS || axis == Z_AXIS) {
            _axis = axis;
            return;
        }
        throw new Error("Invalid axis: string value must be 'x', 'y' or 'z'");
    }

    static private function checkCondition(condition:String):Void {
        condition = condition.toLowerCase();
        var aConds:Array<Dynamic> = [POSITIVE, NEGATIVE, "", AVERAGE];
        var i:Int = 0;
        while (i < aConds.length) {
            if (aConds[i] == condition) {
                _condition = condition;
                return;
            }
            ++i;
        }
        throw new Error("Invalid condition: possible string value are '+', '-', 'av' or '' ");
    }

    static private function getMin(a:Array<Dynamic>, prop:String):Float {
        var min:Float = Infinity;
        var i:Int = 0;
        while (i < a.length) {
            min = Math.min(a[i][prop], min);
            ++i;
        }
        return min;
    }

    static private function getMax(a:Array<Dynamic>, prop:String):Float {
        var max:Float = -Infinity;
        var i:Int = 0;
        while (i < a.length) {
            max = Math.max(a[i][prop], max);
            ++i;
        }
        return max;
    }

    static private function getAverage(a:Array<Dynamic>, prop:String):Float {
        var av:Float = 0;
        var loop:Int = a.length;
        var i:Int = 0;
        while (i < loop) {
            av += a[i][prop];
            ++i;
        }
        return av / loop;
    }

    static private function getMeshesBounds(meshes:Vector<Mesh>):Vector<MeshBound> {
        var mbs:Vector<MeshBound> = new Vector<MeshBound>();
        var mb:MeshBound;
        var i:Int = 0;
        while (i < meshes.length) {
            Bounds.getMeshBounds(meshes[i]);
            mb = new MeshBound();
            mb.mesh = meshes[i];
            mb.minX = Bounds.minX;
            mb.minY = Bounds.minY;
            mb.minZ = Bounds.minZ;
            mb.maxX = Bounds.maxX;
            mb.maxY = Bounds.maxY;
            mb.maxZ = Bounds.maxZ;
            mbs.push(mb);
            ++i;
        }
        return mbs;
    }

    static private function getProp():String {
        var prop:String;
        switch(_axis) {
            case X_AXIS:
                prop = ((_condition == POSITIVE)) ? "maxX" : "minX";
            case Y_AXIS:
                prop = ((_condition == POSITIVE)) ? "maxY" : "minY";
            case Z_AXIS:
                prop = ((_condition == POSITIVE)) ? "maxZ" : "minZ";
        }
        return prop;
    }

    static private function getMinBounds(bounds:Vector<MeshBound>):Float {
        var min:Float = Infinity;
        var mb:MeshBound;
        var i:Int = 0;
        while (i < bounds.length) {
            mb = bounds[i];
            switch(_axis) {
                case X_AXIS:
                    min = Math.min(mb.maxX + mb.mesh.x, min);
                case Y_AXIS:
                    min = Math.min(mb.maxY + mb.mesh.y, min);
                case Z_AXIS:
                    min = Math.min(mb.maxZ + mb.mesh.z, min);
            }
            ++i;
        }
        return min;
    }

    static private function getMaxBounds(bounds:Vector<MeshBound>):Float {
        var max:Float = -Infinity;
        var mb:MeshBound;
        var i:Int = 0;
        while (i < bounds.length) {
            mb = bounds[i];
            switch(_axis) {
                case X_AXIS:
                    max = Math.max(mb.maxX + mb.mesh.x, max);
                case Y_AXIS:
                    max = Math.max(mb.maxY + mb.mesh.y, max);
                case Z_AXIS:
                    max = Math.max(mb.maxZ + mb.mesh.z, max);
            }
            ++i;
        }
        return max;
    }

}

class MeshBound {

    public var mesh:Mesh;
    public var minX:Float;
    public var minY:Float;
    public var minZ:Float;
    public var maxX:Float;
    public var maxY:Float;
    public var maxZ:Float;

    public function new() {}
}

