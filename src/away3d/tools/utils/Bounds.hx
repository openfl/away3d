/**
 * Helper Class to retrieve objects bounds <code>Bounds</code>
 */
package away3d.tools.utils;

import away3d.core.math.MathConsts;
import away3d.core.math.MathConsts;
import away3d.core.math.MathConsts;
import away3d.core.math.MathConsts;
import away3d.core.math.MathConsts;
import flash.Vector;
import away3d.lights.LightBase;
import haxe.ds.ObjectMap;
import away3d.entities.Entity;
import flash.geom.Matrix3D;

import away3d.containers.ObjectContainer3D;
import away3d.entities.Mesh;
import flash.geom.Vector3D;

class Bounds {
    static public var minX(get_minX, never):Float;
    static public var minY(get_minY, never):Float;
    static public var minZ(get_minZ, never):Float;
    static public var maxX(get_maxX, never):Float;
    static public var maxY(get_maxY, never):Float;
    static public var maxZ(get_maxZ, never):Float;
    static public var width(get_width, never):Float;
    static public var height(get_height, never):Float;
    static public var depth(get_depth, never):Float;

    static private var _minX:Float;
    static private var _minY:Float;
    static private var _minZ:Float;
    static private var _maxX:Float;
    static private var _maxY:Float;
    static private var _maxZ:Float;
    static private var _defaultPosition:Vector3D = new Vector3D(0.0, 0.0, 0.0);
    static private var _containers:ObjectMap<ObjectContainer3D, Vector<Float>>;
/**
	 * Calculate the bounds of a Mesh object
	 * @param mesh        Mesh. The Mesh to get the bounds from.
	 * Use the getters of this class to retrieve the results
	 */

    static public function getMeshBounds(mesh:Mesh):Void {
        getObjectContainerBounds(mesh);
    }

/**
	 * Calculate the bounds of an ObjectContainer3D object
	 * @param container        ObjectContainer3D. The ObjectContainer3D to get the bounds from.
	 * Use the getters of this class to retrieve the results
	 */

    static public function getObjectContainerBounds(container:ObjectContainer3D, worldBased:Bool = true):Void {
        reset();
        parseObjectContainerBounds(container);
        if (isInfinite(_minX) || isInfinite(_minY) || isInfinite(_minZ) || isInfinite(_maxX) || isInfinite(_maxY) || isInfinite(_maxZ)) {
            return;
        }
        if (worldBased) {
            var b:Vector<Float> = Vector.ofArray(cast [MathConsts.Infinity, MathConsts.Infinity, MathConsts.Infinity, -MathConsts.Infinity, -MathConsts.Infinity, -MathConsts.Infinity]);
            var c:Vector<Float> = getBoundsCorners(_minX, _minY, _minZ, _maxX, _maxY, _maxZ);
            transformContainer(b, c, container.sceneTransform);
            _minX = b[0];
            _minY = b[1];
            _minZ = b[2];
            _maxX = b[3];
            _maxY = b[4];
            _maxZ = b[5];
        }
    }

/**
	 * Calculate the bounds from a vector of number representing the vertices. &lt;x,y,z,x,y,z.....&gt;
	 * @param vertices        Vector.&lt;Number&gt;. The vertices to get the bounds from.
	 * Use the getters of this class to retrieve the results
	 */

    static public function getVerticesVectorBounds(vertices:Vector<Float>):Void {
        reset();
        var l:Int = vertices.length;
        if (l % 3 != 0) return;
        var x:Float;
        var y:Float;
        var z:Float;
        var i:Int = 0;
        while (i < l) {
            x = vertices[i];
            y = vertices[i + 1];
            z = vertices[i + 2];
            if (x < _minX) _minX = x;
            if (x > _maxX) _maxX = x;
            if (y < _minY) _minY = y;
            if (y > _maxY) _maxY = y;
            if (z < _minZ) _minZ = z;
            if (z > _maxZ) _maxZ = z;
            i += 3;
        }
    }

/**
	 * @param outCenter        Vector3D. Optional Vector3D, if provided the same Vector3D is returned with the bounds center.
	 * @return the center of the bound
	 */

    static public function getCenter(outCenter:Vector3D = null):Vector3D {
        var center:Vector3D = outCenter;
        if (center == null)center = new Vector3D();
        center.x = _minX + (_maxX - _minX) * .5;
        center.y = _minY + (_maxY - _minY) * .5;
        center.z = _minZ + (_maxZ - _minZ) * .5;
        return center;
    }

/**
	 * @return the smalest x value
	 */

    static public function get_minX():Float {
        return _minX;
    }

/**
	 * @return the smalest y value
	 */

    static public function get_minY():Float {
        return _minY;
    }

/**
	 * @return the smalest z value
	 */

    static public function get_minZ():Float {
        return _minZ;
    }

/**
	 * @return the biggest x value
	 */

    static public function get_maxX():Float {
        return _maxX;
    }

/**
	 * @return the biggest y value
	 */

    static public function get_maxY():Float {
        return _maxY;
    }

/**
	 * @return the biggest z value
	 */

    static public function get_maxZ():Float {
        return _maxZ;
    }

/**
	 * @return the width value from the bounds
	 */

    static public function get_width():Float {
        return _maxX - _minX;
    }

/**
	 * @return the height value from the bounds
	 */

    static public function get_height():Float {
        return _maxY - _minY;
    }

/**
	 * @return the depth value from the bounds
	 */

    static public function get_depth():Float {
        return _maxZ - _minZ;
    }

    static public function reset():Void {
        _containers = new ObjectMap<ObjectContainer3D, Vector<Float>>();
        _minX = _minY = _minZ = MathConsts.Infinity;
        _maxX = _maxY = _maxZ = -MathConsts.Infinity;
        _defaultPosition.x = 0.0;
        _defaultPosition.y = 0.0;
        _defaultPosition.z = 0.0;
    }

    static private function parseObjectContainerBounds(obj:ObjectContainer3D, parentTransform:Matrix3D = null):Void {
        if (!obj.visible) return;
        if (!_containers.exists(obj))
            _containers.set(obj, Vector.ofArray([Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY,
            Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY]));
        var containerBounds:Vector<Float> = _containers.get(obj);
        var child:ObjectContainer3D;
        var isEntity:Entity = cast(obj, Entity);
        var containerTransform:Matrix3D = new Matrix3D();
        if (isEntity != null && parentTransform != null) {
            parseObjectBounds(obj, parentTransform);
            containerTransform = obj.transform.clone();
            if (parentTransform != null) containerTransform.append(parentTransform);
        }

        else if (isEntity != null && parentTransform == null) {
            var mat:Matrix3D = obj.transform.clone();
            mat.invert();
            parseObjectBounds(obj, mat);
        }
        var i:Int = 0;
        while (i < obj.numChildren) {
            child = obj.getChildAt(i);
            parseObjectContainerBounds(child, containerTransform);
            ++i;
        }
        var parentBounds:Vector<Float> = _containers.get(obj.parent);
        if (isEntity == null && parentTransform != null) parseObjectBounds(obj, parentTransform, true);
        if (parentBounds != null) {
            parentBounds[0] = Math.min(parentBounds[0], containerBounds[0]);
            parentBounds[1] = Math.min(parentBounds[1], containerBounds[1]);
            parentBounds[2] = Math.min(parentBounds[2], containerBounds[2]);
            parentBounds[3] = Math.max(parentBounds[3], containerBounds[3]);
            parentBounds[4] = Math.max(parentBounds[4], containerBounds[4]);
            parentBounds[5] = Math.max(parentBounds[5], containerBounds[5]);
        }

        else {
            _minX = containerBounds[0];
            _minY = containerBounds[1];
            _minZ = containerBounds[2];
            _maxX = containerBounds[3];
            _maxY = containerBounds[4];
            _maxZ = containerBounds[5];
        }

    }

    static private function isInfinite(value:Float):Bool {
        return value == MathConsts.POSITIVE_INFINITY || value == MathConsts.NEGATIVE_INFINITY;
    }

    static private function parseObjectBounds(oC:ObjectContainer3D, parentTransform:Matrix3D = null, resetBounds:Bool = false):Void {
        if (Std.is(oC, LightBase)) return;
        var e:Entity = cast(oC, Entity);
        var corners:Vector<Float>;
        var mat:Matrix3D = oC.transform.clone();
        var cB:Vector<Float> = _containers.get(oC);
        if (e != null) {
            if (isInfinite(e.minX) || isInfinite(e.minY) || isInfinite(e.minZ) || isInfinite(e.maxX) || isInfinite(e.maxY) || isInfinite(e.maxZ)) {
                return;
            }
            corners = getBoundsCorners(e.minX, e.minY, e.minZ, e.maxX, e.maxY, e.maxZ);
            if (parentTransform != null) mat.append(parentTransform);
        }

        else {
            corners = getBoundsCorners(cB[0], cB[1], cB[2], cB[3], cB[4], cB[5]);
            if (parentTransform != null) mat.prepend(parentTransform);
        }

        if (resetBounds) {
            cB[0] = cB[1] = cB[2] = MathConsts.Infinity;
            cB[3] = cB[4] = cB[5] = -MathConsts.Infinity;
        }
        transformContainer(cB, corners, mat);
    }

    static private function getBoundsCorners(minX:Float, minY:Float, minZ:Float, maxX:Float, maxY:Float, maxZ:Float):Vector<Float> {
        return Vector.ofArray(cast [minX, minY, minZ, minX, minY, maxZ, minX, maxY, minZ, minX, maxY, maxZ, maxX, minY, minZ, maxX, minY, maxZ, maxX, maxY, minZ, maxX, maxY, maxZ]);
    }

    static private function transformContainer(bounds:Vector<Float>, corners:Vector<Float>, matrix:Matrix3D):Void {
        matrix.transformVectors(corners, corners);
        var x:Float;
        var y:Float;
        var z:Float;
        var pCtr:Int = 0;
        while (pCtr < corners.length) {
            x = corners[pCtr++];
            y = corners[pCtr++];
            z = corners[pCtr++];
            if (x < bounds[0]) bounds[0] = x;
            if (x > bounds[3]) bounds[3] = x;
            if (y < bounds[1]) bounds[1] = y;
            if (y > bounds[4]) bounds[4] = y;
            if (z < bounds[2]) bounds[2] = z;
            if (z > bounds[5]) bounds[5] = z;
        }

    }

}

