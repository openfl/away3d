package away3d.tools.utils;


import away3d.core.math.MathConsts;
import away3d.core.base.CompactSubGeometry;
import away3d.core.base.SubGeometry;
import away3d.core.base.Geometry;
import flash.Vector;
import away3d.core.base.ISubGeometry;
import away3d.entities.Mesh;
import flash.geom.Vector3D;
import away3d.core.base.data.UV;
import away3d.containers.ObjectContainer3D;
class Projector {

    static public var FRONT:String = "front";
    static public var BACK:String = "back";
    static public var TOP:String = "top";
    static public var BOTTOM:String = "bottom";
    static public var LEFT:String = "left";
    static public var RIGHT:String = "right";
    static public var CYLINDRICAL_X:String = "cylindricalx";
    static public var CYLINDRICAL_Y:String = "cylindricaly";
    static public var CYLINDRICAL_Z:String = "cylindricalz";
    static public var SPHERICAL:String = "spherical";
    static private var _width:Float;
    static private var _height:Float;
    static private var _depth:Float;
    static private var _offsetW:Float;
    static private var _offsetH:Float;
    static private var _offsetD:Float;
    static private var _orientation:String;
    static private var _center:Vector3D;
    static private var _vn:Vector3D;
    static private var _ve:Vector3D;
    static private var _vp:Vector3D;
    static private var _dir:Vector3D;
    static private var _radius:Float;
    static private var _uv:UV;
    static private var PI:Float = Math.PI;
    static private var DOUBLEPI:Float = Math.PI * 2;
/**
	 * Class remaps the uv data of a mesh
	 *
	 * @param     orientation    String. Defines the projection direction and methods.
	 * Note: As we use triangles, cylindrical and spherical projections might require correction,
	 * as some faces, may have vertices pointing at other side of the map, causing some faces to be rendered as a whole reverted map.
	 *
	 * @param     obj        ObjectContainer3D. The ObjectContainer3D to remap.
	 */

    static public function project(orientation:String, obj:ObjectContainer3D):Void {
        _orientation = orientation.toLowerCase();
        parse(obj);
    }

    static private function parse(obj:ObjectContainer3D):Void {
        var child:ObjectContainer3D;
        if (Std.is(obj, Mesh) && obj.numChildren == 0) remapMesh(cast((obj), Mesh));
        var i:Int = 0;
        while (i < obj.numChildren) {
            child = obj.getChildAt(i);
            parse(child);
            ++i;
        }
    }

    static private function remapMesh(mesh:Mesh):Void {
        var minX:Float = MathConsts.Infinity;
        var minY:Float = MathConsts.Infinity;
        var minZ:Float = MathConsts.Infinity;
        var maxX:Float = -MathConsts.Infinity;
        var maxY:Float = -MathConsts.Infinity;
        var maxZ:Float = -MathConsts.Infinity;
        Bounds.getMeshBounds(mesh);
        minX = Bounds.minX;
        minY = Bounds.minY;
        minZ = Bounds.minZ;
        maxX = Bounds.maxX;
        maxY = Bounds.maxY;
        maxZ = Bounds.maxZ;
        if (_orientation == FRONT || _orientation == BACK || _orientation == CYLINDRICAL_X) {
            _width = maxX - minX;
            _height = maxY - minY;
            _depth = maxZ - minZ;
            _offsetW = ((minX > 0)) ? -minX : Math.abs(minX);
            _offsetH = ((minY > 0)) ? -minY : Math.abs(minY);
            _offsetD = ((minZ > 0)) ? -minZ : Math.abs(minZ);
        }

        else if (_orientation == LEFT || _orientation == RIGHT || _orientation == CYLINDRICAL_Z) {
            _width = maxZ - minZ;
            _height = maxY - minY;
            _depth = maxX - minX;
            _offsetW = ((minZ > 0)) ? -minZ : Math.abs(minZ);
            _offsetH = ((minY > 0)) ? -minY : Math.abs(minY);
            _offsetD = ((minX > 0)) ? -minX : Math.abs(minX);
        }

        else if (_orientation == TOP || _orientation == BOTTOM || _orientation == CYLINDRICAL_Y) {
            _width = maxX - minX;
            _height = maxZ - minZ;
            _depth = maxY - minY;
            _offsetW = ((minX > 0)) ? -minX : Math.abs(minX);
            _offsetH = ((minZ > 0)) ? -minZ : Math.abs(minZ);
            _offsetD = ((minY > 0)) ? -minY : Math.abs(minY);
        }
        var geometry:Geometry = mesh.geometry;
        var geometries:Vector<ISubGeometry> = geometry.subGeometries;
        if (_orientation == SPHERICAL) {
            if (_center == null) _center = new Vector3D();
            _width = maxX - minX;
            _height = maxZ - minZ;
            _depth = maxY - minY;
            _radius = Math.max(Math.max(_width, _depth), _height) + 10;
            _center.x = _center.y = _center.z = .0001;
            remapSpherical(geometries, mesh.scenePosition);
        }

        else if (_orientation.indexOf("cylindrical") != -1) remapCylindrical(geometries, mesh.scenePosition)
        else remapLinear(geometries, mesh.scenePosition);
    }

    static private function remapLinear(geometries:Vector<ISubGeometry>, position:Vector3D):Void {
        var numSubGeoms:Int = geometries.length;
        var sub_geom:ISubGeometry;
        var vertices:Vector<Float>;
        var vertexOffset:Int;
        var vertexStride:Int;
        var indices:Vector<UInt>;
        var uvs:Vector<Float>;
        var uvOffset:Int;
        var uvStride:Int;
        var i:Int = 0;
        var j:Int;
        var vIndex:Int;
        var uvIndex:Int;
        var numIndices:Int;
        var offsetU:Float;
        var offsetV:Float;
        i = 0;
        while (i < numSubGeoms) {
            sub_geom = geometries[i];
            vertices = sub_geom.vertexData;
            vertexOffset = sub_geom.vertexOffset;
            vertexStride = sub_geom.vertexStride;
            uvs = sub_geom.UVData;
            uvOffset = sub_geom.UVOffset;
            uvStride = sub_geom.UVStride;
            indices = sub_geom.indexData;
            numIndices = indices.length;
            switch(_orientation) {
                case Projector.FRONT:
                    offsetU = _offsetW + position.x;
                    offsetV = _offsetH + position.y;
                    j = 0;
                    while (j < numIndices) {
                        vIndex = vertexOffset + vertexStride * indices[j];
                        uvIndex = uvOffset + uvStride * indices[j];
                        uvs[uvIndex] = (vertices[vIndex] + offsetU) / _width;
                        uvs[uvIndex + 1] = 1 - (vertices[vIndex + 1] + offsetV) / _height;
                        ++j;
                    }
                case Projector.BACK:
                    offsetU = _offsetW + position.x;
                    offsetV = _offsetH + position.y;
                    j = 0;
                    while (j < numIndices) {
                        vIndex = vertexOffset + vertexStride * indices[j];
                        uvIndex = uvOffset + uvStride * indices[j];
                        uvs[uvIndex] = 1 - (vertices[vIndex] + offsetU) / _width;
                        uvs[uvIndex + 1] = 1 - (vertices[vIndex + 1] + offsetV) / _height;
                        ++j;
                    }
                case Projector.RIGHT:
                    offsetU = _offsetW + position.z;
                    offsetV = _offsetH + position.y;
                    j = 0;
                    while (j < numIndices) {
                        vIndex = vertexOffset + vertexStride * indices[j] + 1;
                        uvIndex = uvOffset + uvStride * indices[j];
                        uvs[uvIndex] = (vertices[vIndex + 1] + offsetU) / _width;
                        uvs[uvIndex + 1] = 1 - (vertices[vIndex] + offsetV) / _height;
                        ++j;
                    }
                case Projector.LEFT:
                    offsetU = _offsetW + position.z;
                    offsetV = _offsetH + position.y;
                    j = 0;
                    while (j < numIndices) {
                        vIndex = vertexOffset + vertexStride * indices[j] + 1;
                        uvIndex = uvOffset + uvStride * indices[j];
                        uvs[uvIndex] = 1 - (vertices[vIndex + 1] + offsetU) / _width;
                        uvs[uvIndex + 1] = 1 - (vertices[vIndex] + offsetV) / _height;
                        ++j;
                    }
                case Projector.TOP:
                    offsetU = _offsetW + position.x;
                    offsetV = _offsetH + position.z;
                    j = 0;
                    while (j < numIndices) {
                        vIndex = vertexOffset + vertexStride * indices[j];
                        uvIndex = uvOffset + uvStride * indices[j];
                        uvs[uvIndex] = (vertices[vIndex] + offsetU) / _width;
                        uvs[uvIndex + 1] = 1 - (vertices[vIndex + 2] + offsetV) / _height;
                        ++j;
                    }
                case Projector.BOTTOM:
                    offsetU = _offsetW + position.x;
                    offsetV = _offsetH + position.z;
                    j = 0;
                    while (j < numIndices) {
                        vIndex = vertexOffset + vertexStride * indices[j];
                        uvIndex = uvOffset + uvStride * indices[j];
                        uvs[uvIndex] = 1 - (vertices[vIndex] + offsetU) / _width;
                        uvs[uvIndex + 1] = 1 - (vertices[vIndex + 2] + offsetV) / _height;
                        ++j;
                    }
            }
            if (Std.is(sub_geom, CompactSubGeometry)) cast((sub_geom), CompactSubGeometry).updateData(uvs)
            else cast((sub_geom), SubGeometry).updateUVData(uvs);
            ++i;
        }
    }

    static private function remapCylindrical(geometries:Vector<ISubGeometry>, position:Vector3D):Void {
        var numSubGeoms:Int = geometries.length;
        var sub_geom:ISubGeometry;
        var vertices:Vector<Float>;
        var vertexOffset:Int;
        var vertexStride:Int;
        var indices:Vector<UInt>;
        var uvs:Vector<Float>;
        var uvOffset:Int;
        var uvStride:Int;
        var i:Int = 0;
        var j:Int;
        var vIndex:Int;
        var uvIndex:Int;
        var numIndices:Int;
        var offset:Float;
        i = 0;
        while (i < numSubGeoms) {
            sub_geom = geometries[i];
            vertices = sub_geom.vertexData;
            vertexOffset = sub_geom.vertexOffset;
            vertexStride = sub_geom.vertexStride;
            uvs = sub_geom.UVData;
            uvOffset = sub_geom.UVOffset;
            uvStride = sub_geom.UVStride;
            indices = sub_geom.indexData;
            numIndices = indices.length;
            switch(_orientation) {
                case Projector.CYLINDRICAL_X:
                    offset = _offsetW + position.x;
                    j = 0;
                    while (j < numIndices) {
                        vIndex = vertexOffset + vertexStride * indices[j];
                        uvIndex = uvOffset + uvStride * indices[j];
                        uvs[uvIndex] = (vertices[vIndex] + offset) / _width;
                        uvs[uvIndex + 1] = (PI + Math.atan2(vertices[vIndex + 1], vertices[vIndex + 2])) / DOUBLEPI;
                        ++j;
                    }
                case Projector.CYLINDRICAL_Y:
                    offset = _offsetD + position.y;
                    j = 0;
                    while (j < numIndices) {
                        vIndex = vertexOffset + vertexStride * indices[j];
                        uvIndex = uvOffset + uvStride * indices[j];
                        uvs[uvIndex] = (PI + Math.atan2(vertices[vIndex], vertices[vIndex + 2])) / DOUBLEPI;
                        uvs[uvIndex + 1] = 1 - (vertices[vIndex + 1] + offset) / _depth;
                        ++j;
                    }
                case Projector.CYLINDRICAL_Z:
                    offset = _offsetW + position.z;
                    j = 0;
                    while (j < numIndices) {
                        vIndex = vertexOffset + vertexStride * indices[j];
                        uvIndex = uvOffset + uvStride * indices[j];
                        uvs[uvIndex + 1] = (vertices[vIndex + 2] + offset) / _width;
                        uvs[uvIndex] = (PI + Math.atan2(vertices[vIndex + 1], vertices[vIndex])) / DOUBLEPI;
                        ++j;
                    }
            }
            if (Std.is(sub_geom, CompactSubGeometry)) cast((sub_geom), CompactSubGeometry).updateData(uvs)
            else cast((sub_geom), SubGeometry).updateUVData(uvs);
            ++i;
        }
    }

    static private function remapSpherical(geometries:Vector<ISubGeometry>, position:Vector3D):Void {

        var numSubGeoms:Int = geometries.length;
        var sub_geom:ISubGeometry;
        var vertices:Vector<Float>;
        var vertexOffset:Int;
        var vertexStride:Int;
        var indices:Vector<UInt>;
        var uvs:Vector<Float>;
        var uvOffset:Int;
        var uvStride:Int;
        var i:Int = 0;
        var j:Int;
        var vIndex:Int;
        var uvIndex:Int;
        var numIndices:Int;
        i = 0;
        while (i < numSubGeoms) {
            sub_geom = geometries[i];
            vertices = sub_geom.vertexData;
            vertexOffset = sub_geom.vertexOffset;
            vertexStride = sub_geom.vertexStride;
            uvs = sub_geom.UVData;
            uvOffset = sub_geom.UVOffset;
            uvStride = sub_geom.UVStride;
            indices = sub_geom.indexData;
            numIndices = indices.length;
            numIndices = indices.length;
            j = 0;
            while (j < numIndices) {
                vIndex = vertexOffset + vertexStride * indices[j];
                uvIndex = uvOffset + uvStride * indices[j];
                projectVertex(vertices[vIndex], vertices[vIndex + 1], vertices[vIndex + 2]);
                uvs[uvIndex] = _uv.u;
                uvs[uvIndex + 1] = _uv.v;
                ++j;
            }
            if (Std.is(sub_geom, CompactSubGeometry)) cast((sub_geom), CompactSubGeometry).updateData(uvs)
            else cast((sub_geom), SubGeometry).updateUVData(uvs);
            ++i;
        }
    }

    static private function projectVertex(x:Float, y:Float, z:Float):Void {
        if (_dir == null) {
            _dir = new Vector3D(x, y, z);
            _uv = new UV();
            _vn = new Vector3D(0, -1, 0);
            _ve = new Vector3D(.1, 0, .9);
            _vp = new Vector3D();
        }

        else {
            _dir.x = x;
            _dir.y = y;
            _dir.z = z;
        }

        _dir.normalize();
        _vp.x = _dir.x * _radius;
        _vp.y = _dir.y * _radius;
        _vp.z = _dir.z * _radius;
        _vp.normalize();
        var phi:Float = Math.acos(-_vn.dotProduct(_vp));
        _uv.v = phi / PI;
        var theta:Float = Math.acos(_vp.dotProduct(_ve) / Math.sin(phi)) / DOUBLEPI;
        var _crp:Vector3D = _vn.crossProduct(_ve);
        if (_crp.dotProduct(_vp) < 0) _uv.u = 1 - theta
        else _uv.u = theta;
    }

}

