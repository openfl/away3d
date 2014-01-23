/**
 * Class for generating meshes with axial symmetry such as donuts, pipes, vases etc.
 */
package away3d.extrusions;

import away3d.extrusions.data.Line;
import away3d.extrusions.data.FourPoints;
import away3d.extrusions.data.RenderSide;
import away3d.extrusions.data.SubGeometryList;
import flash.errors.Error;
import flash.Vector;
import away3d.bounds.BoundingVolumeBase;
import away3d.core.base.Geometry;
import away3d.core.base.SubGeometry;
import away3d.core.base.SubMesh;
import away3d.core.base.data.UV;
import away3d.entities.Mesh;
import away3d.materials.MaterialBase;
import away3d.materials.utils.MultipleMaterials;
import away3d.tools.helpers.MeshHelper;
import flash.geom.Point;
import flash.geom.Vector3D;
import away3d.core.base.SubGeometry;
import away3d.materials.MaterialBase;
import flash.geom.Point;

class LatheExtrude extends Mesh {
    public var profile(get_profile, set_profile):Vector<Vector3D>;
    public var startRotationOffset(get_startRotationOffset, set_startRotationOffset):Float;
    public var axis(get_axis, set_axis):String;
    public var revolutions(get_revolutions, set_revolutions):Float;
    public var subdivision(get_subdivision, set_subdivision):Int;
    public var offsetRadius(get_offsetRadius, set_offsetRadius):Float;
    public var materials(get_materials, set_materials):MultipleMaterials;
    public var coverAll(get_coverAll, set_coverAll):Bool;
    public var flip(get_flip, set_flip):Bool;
    public var smoothSurface(get_smoothSurface, set_smoothSurface):Bool;
    public var keepLastProfile(get_keepLastProfile, set_keepLastProfile):Bool;
    public var lastProfile(get_lastProfile, never):Vector<Vector3D>;
    public var preciseThickness(get_preciseThickness, set_preciseThickness):Bool;
    public var centerMesh(get_centerMesh, set_centerMesh):Bool;
    public var thickness(get_thickness, set_thickness):Float;
    public var ignoreSides(get_ignoreSides, set_ignoreSides):String;
    public var tweek(get_tweek, set_tweek):Dynamic;

    private var EPS:Float;
    private var LIMIT:Int;
    private var MAXRAD:Float;
    private var _profile:Vector<Vector3D>;
    private var _lastProfile:Vector<Vector3D>;
    private var _keepLastProfile:Bool;
    private var _axis:String;
    private var _revolutions:Float;
    private var _subdivision:Int;
    private var _offsetRadius:Float;
    private var _prevOffsetRadius:Float;
    private var _materials:MultipleMaterials;
    private var _coverAll:Bool;
    private var _flip:Bool;
    private var _centerMesh:Bool;
    private var _thickness:Float;
    private var _preciseThickness:Bool;
    private var _ignoreSides:String;
    private var _smoothSurface:Bool;
    private var _tweek:Dynamic;
    private var _varr:Vector<Vector3D>;
    private var _varr2:Vector<Vector3D>;
    private var _uvarr:Vector<UV>;
    private var _startRotationOffset:Float;
    private var _geomDirty:Bool;
    private var _subGeometry:SubGeometry;
    private var _MaterialsSubGeometries:Vector<SubGeometryList>;
    private var _maxIndProfile:Int;
    private var _uva:UV;
    private var _uvb:UV;
    private var _uvc:UV;
    private var _uvd:UV;
    private var _va:Vector3D;
    private var _vb:Vector3D;
    private var _vc:Vector3D;
    private var _vd:Vector3D;
    private var _uvs:Vector<Float>;
    private var _vertices:Vector<Float>;
    private var _indices:Vector<UInt>;
    private var _normals:Vector<Float>;
    private var _normalTmp:Vector3D;
    private var _normal0:Vector3D;
    private var _normal1:Vector3D;
    private var _normal2:Vector3D;
    static public var X_AXIS:String = "x";
    static public var Y_AXIS:String = "y";
    static public var Z_AXIS:String = "z";
/**
	 *  Class LatheExtrude generates circular meshes such as donuts, pipes, pyramids etc.. from a series of Vector3D's
	 *
	 *@param        material                [optional] MaterialBase. The LatheExtrude (Mesh) material. Optional in constructor, material must be set before LatheExtrude object is render.
	 * @param        profile                [optional] Vector.&lt;Vector3D&gt;. A series of Vector3D's representing the profile information to be repeated/rotated around a given axis.
	 * @param        axis                    [optional] String. The axis to rotate around: X_AXIS, Y_AXIS or Z_AXIS. Default is LatheExtrude.Y_AXIS.
	 * @param        revolutions            [optional] Number. The LatheExtrude object can have less than one revolution, like 0.6 for a piechart or greater than 1 if a tweek object is passed. Minimum is 0.01. Default is 1.
	 * @param        subdivision            [optional] uint. Howmany segments will compose the mesh in its rotational construction. Minimum is 3. Default is 10.
	 * @param        coverall                [optional] Boolean. The way the uv mapping is spreaded across the shape. True covers an entire side of the geometry while false covers per segments. Default is true.
	 * @param        flip                    [optional] Boolean. If the faces must be reversed depending on Vector3D's orientation. Default is false.
	 * @param        thickness            [optional] Number. If the shape must simulate a thickness. Default is 0.
	 * @param        preciseThickness    [optional] Boolean. If the thickness must be repected along the entire volume profile. Default is true.
	 * @param        centerMesh        [optional] Boolean. If the geometry needs to be recentered in its own object space. If the position after generation is set to 0,0,0, the object would be centered in worldspace. Default is false.
	 * @param        offsetRadius        [optional] Number. An offset radius if the profile data is not to be updated but the radius expected to be different. Default is 0.
	 * @param        materials            [optional] MultipleMaterials. Allows multiple material support when thickness is set higher to 1. Default is null.
	 * properties as MaterialBase are: bottom, top, left, right, front and back.
	 * @param        ignoreSides        [optional] String. To prevent the generation of sides if thickness is set higher than 0. To avoid the bottom ignoreSides = "bottom", avoiding both top and bottom: ignoreSides = "bottom, top". Strings options: bottom, top, left, right, front and back. Default is "".
	 * @param        tweek                [optional] Object. To build springs like shapes, rotation must be higher than 1. Properties of the tweek object are x,y,z, radius and rotation. Default is null.
	 * @param        smoothSurface    [optional]    An optional Boolean. Defines if the surface of the mesh must be smoothed or not.
	 */

    public function new(material:MaterialBase = null, profile:Vector<Vector3D> = null, axis:String = LatheExtrude.Y_AXIS, revolutions:Float = 1, subdivision:Int = 10, coverall:Bool = true, centerMesh:Bool = false, flip:Bool = false, thickness:Float = 0, preciseThickness:Bool = true, offsetRadius:Float = 0, materials:MultipleMaterials = null, ignoreSides:String = "", tweek:Dynamic = null, smoothSurface:Bool = true) {
        EPS = .0001;
        LIMIT = 196605;
        MAXRAD = 1.2;
        _prevOffsetRadius = 0;
        _startRotationOffset = 0;
        _geomDirty = true;
        _MaterialsSubGeometries = new Vector<SubGeometryList>();
        var geom:Geometry = new Geometry();
        _subGeometry = new SubGeometry();
        if (!material && materials && materials.front) material = materials.front;
        super(geom, material);
        _profile = profile;
        _axis = axis;
        _revolutions = revolutions;
        _subdivision = ((subdivision < 3)) ? 3 : subdivision;
        _offsetRadius = offsetRadius;
        _materials = materials;
        _coverAll = coverall;
        _flip = flip;
        _centerMesh = centerMesh;
        _thickness = Math.abs(thickness);
        _preciseThickness = preciseThickness;
        _ignoreSides = ignoreSides;
        _tweek = tweek;
        _smoothSurface = smoothSurface;
    }

/*
	 * A Vector.<Vector3D> representing the profile information to be repeated/rotated around a given axis.
	 */

    public function get_profile():Vector<Vector3D> {
        return _profile;
    }

    public function set_profile(val:Vector<Vector3D>):Vector<Vector3D> {
        if (val.length > 1) {
            _profile = val;
            invalidateGeometry();
        }

        else throw new Error("LatheExtrude error: the profile Vector.<Vector3D> must hold a mimimun of 2 vector3D's");
        return val;
    }

/*
	 * A Number, to offset the original start angle of the rotation. Default is 0;
	 */

    public function get_startRotationOffset():Float {
        return _startRotationOffset;
    }

    public function set_startRotationOffset(val:Float):Float {
        _startRotationOffset = val;
        return val;
    }

/**
	 * Defines the axis used for the lathe rotation. Defaults to "y".
	 */

    public function get_axis():String {
        return _axis;
    }

    public function set_axis(val:String):String {
        if (_axis == val) return;
        _axis = val;
        invalidateGeometry();
        return val;
    }

/**
	 * Defines the number of revolutions performed by the lathe extrusion. Defaults to 1.
	 */

    public function get_revolutions():Float {
        return _revolutions;
    }

    public function set_revolutions(val:Float):Float {
        if (_revolutions == val) return;
        _revolutions = ((_revolutions > .001)) ? _revolutions : .001;
        _revolutions = val;
        invalidateGeometry();
        return val;
    }

/**
	 * Defines the subdivisions created in the mesh for the total number of revolutions. Defaults to 2, minimum 2.
	 *
	 * @see #revolutions
	 */

    public function get_subdivision():Int {
        return _subdivision;
    }

    public function set_subdivision(val:Int):Int {
        val = ((val < 3)) ? 3 : val;
        if (_subdivision == val) return;
        _subdivision = val;
        invalidateGeometry();
        return val;
    }

/**
	 * Defines an offset radius applied to the profile. Defaults to 0.
	 */

    public function get_offsetRadius():Float {
        return _offsetRadius;
    }

    public function set_offsetRadius(val:Float):Float {
        if (_offsetRadius == val) return;
        _offsetRadius = val;
        invalidateGeometry();
        return val;
    }

/**
	 * An optional object that defines left, right, front, back, top and bottom materials to be set on the resulting lathe extrusion.
	 */

    public function get_materials():MultipleMaterials {
        return _materials;
    }

    public function set_materials(val:MultipleMaterials):MultipleMaterials {
        _materials = val;
        if (_materials.front && this.material != _materials.front) this.material = _materials.front;
        invalidateGeometry();
        return val;
    }

/**
	 * Defines if the texture(s) should be stretched to cover the entire mesh or per step between segments. Defaults to true.
	 */

    public function get_coverAll():Bool {
        return _coverAll;
    }

    public function set_coverAll(val:Bool):Bool {
        if (_coverAll == val) return;
        _coverAll = val;
        invalidateGeometry();
        return val;
    }

/**
	 * Defines if the generated faces should be inversed. Default false.
	 */

    public function get_flip():Bool {
        return _flip;
    }

    public function set_flip(val:Bool):Bool {
        if (_flip == val) return;
        _flip = val;
        invalidateGeometry();
        return val;
    }

/**
	 * Defines if the surface of the mesh must be smoothed or not.
	 */

    public function get_smoothSurface():Bool {
        return _smoothSurface;
    }

    public function set_smoothSurface(val:Bool):Bool {
        if (_smoothSurface == val) return;
        _smoothSurface = val;
        _geomDirty = true;
        return val;
    }

/**
	 * Defines if the last transformed profile values are saved or not. Useful in combo with rotations less than 1, to ease combinations with other extrusions classes such as SkinExtrude.
	 */

    public function get_keepLastProfile():Bool {
        return _keepLastProfile;
    }

    public function set_keepLastProfile(val:Bool):Bool {
        if (_keepLastProfile == val) return;
        _keepLastProfile = val;
        return val;
    }

/**
	 * returns the last rotated profile values, if keepLastProfile was true
	 */

    public function get_lastProfile():Vector<Vector3D> {
        if (keepLastProfile && !_lastProfile) buildExtrude();
        return _lastProfile;
    }

/**
	 * Defines if thickness is greater than 0 if the thickness is equally distributed along the volume. Default is false.
	 */

    public function get_preciseThickness():Bool {
        return _preciseThickness;
    }

    public function set_preciseThickness(val:Bool):Bool {
        if (_preciseThickness == val) return;
        _preciseThickness = val;
        invalidateGeometry();
        return val;
    }

/**
	 * Defines whether the mesh is recentered of not after generation
	 */

    public function get_centerMesh():Bool {
        return _centerMesh;
    }

    public function set_centerMesh(val:Bool):Bool {
        if (_centerMesh == val) return;
        _centerMesh = val;
        if (_centerMesh && _subGeometry.vertexData.length > 0) MeshHelper.recenter(this)
        else invalidateGeometry();
        return val;
    }

/**
	 * Defines the thickness of the resulting lathed geometry. Defaults to 0 (single face).
	 */

    public function get_thickness():Float {
        return _thickness;
    }

    public function set_thickness(val:Float):Float {
        if (_thickness == val) return;
        _thickness = ((val > 0)) ? val : _thickness;
        invalidateGeometry();
        return val;
    }

/**
	 * Defines if the top, bottom, left, right, front or back of the the extrusion is left open.
	 */

    public function get_ignoreSides():String {
        return _ignoreSides;
    }

    public function set_ignoreSides(val:String):String {
        _ignoreSides = val;
        invalidateGeometry();
        return val;
    }

/**
	 * Allows the building of shapes such as springs. Rotation must be higher than 1 to have significant effect. Properties of the objects are x,y,z,radius and rotation
	 */

    public function get_tweek():Dynamic {
        return _tweek;
    }

    public function set_tweek(val:Dynamic):Dynamic {
        _tweek = val;
        invalidateGeometry();
        return val;
    }

/**
	 * @inheritDoc
	 */

    override public function get_bounds():BoundingVolumeBase {
        if (_geomDirty) buildExtrude();
        return super.bounds;
    }

/**
	 * @inheritDoc
	 */

    override public function get_geometry():Geometry {
        if (_geomDirty) buildExtrude();
        return super.geometry;
    }

/**
	 * @inheritDoc
	 */

    override public function get_subMeshes():Vector<SubMesh> {
        if (_geomDirty) buildExtrude();
        return super.subMeshes;
    }

    private function closeTopBottom(ptLength:Int, renderSide:RenderSide):Void {
        var va:Vector3D;
        var vb:Vector3D;
        var vc:Vector3D;
        var vd:Vector3D;
        var i:Int;
        var j:Int;
        var a:Float;
        var b:Float;
        var total:Int = _varr.length - ptLength;
        _uva.u = _uvb.u = 0;
        _uvc.u = _uvd.u = 1;
        i = 0;
        while (i < total) {
            if (i != 0) {
                if (_coverAll) {
                    a = i / total;
                    b = (i + ptLength) / total;
                    _uva.v = a;
                    _uvb.v = b;
                    _uvc.v = b;
                    _uvd.v = a;
                }

                else {
                    _uva.v = 0;
                    _uvb.v = 1;
                    _uvc.v = 1;
                    _uvd.v = 0;
                }

                if (renderSide.top) {
                    va = _varr[i];
                    vb = _varr[i + ptLength];
                    vc = _varr2[i + ptLength];
                    vd = _varr2[i];
                    if (_flip) {
                        addFace(vb, va, vc, _uvb, _uva, _uvc, 4);
                        addFace(vc, va, vd, _uvc, _uva, _uvd, 4);
                    }

                    else {
                        addFace(va, vb, vc, _uva, _uvb, _uvc, 4);
                        addFace(va, vc, vd, _uva, _uvc, _uvd, 4);
                    }

                }
                if (renderSide.bottom) {
                    j = i + ptLength - 1;
                    va = _varr[j];
                    vb = _varr[j + ptLength];
                    vc = _varr2[j + ptLength];
                    vd = _varr2[j];
                    if (_flip) {
                        addFace(va, vb, vc, _uva, _uvb, _uvc, 5);
                        addFace(va, vc, vd, _uva, _uvc, _uvd, 5);
                    }

                    else {
                        addFace(vb, va, vc, _uvb, _uva, _uvc, 5);
                        addFace(vc, va, vd, _uvc, _uva, _uvd, 5);
                    }

                }
            }
            i += ptLength;
        }
    }

    private function closeSides(ptLength:Int, renderSide:RenderSide):Void {
        var va:Vector3D;
        var vb:Vector3D;
        var vc:Vector3D;
        var vd:Vector3D;
        var total:Int = _varr.length - ptLength;
        var i:Int;
        var j:Int;
        var a:Float;
        var b:Float;
        var iter:Int = ptLength - 1;
        var step:Float = ((_preciseThickness && ptLength % 2 == 0)) ? 1 / iter : 1 / ptLength;
        i = 0;
        while (i < iter) {
            if (_coverAll) {
                a = i * step;
                b = a + step;
                _uva.v = 1 - a;
                _uvb.v = 1 - b;
                _uvc.v = 1 - b;
                _uvd.v = 1 - a;
            }

            else {
                _uva.v = 0;
                _uvb.v = 1;
                _uvc.v = 1;
                _uvd.v = 0;
            }

            if (renderSide.left) {
                va = _varr[i + 1];
                vb = _varr[i];
                vc = _varr2[i];
                vd = _varr2[i + 1];
                _uva.u = _uvb.u = 0;
                _uvc.u = _uvd.u = 1;
                if (_flip) {
                    addFace(vb, va, vc, _uvb, _uva, _uvc, 2);
                    addFace(vc, va, vd, _uvc, _uva, _uvd, 2);
                }

                else {
                    addFace(va, vb, vc, _uva, _uvb, _uvc, 2);
                    addFace(va, vc, vd, _uva, _uvc, _uvd, 2);
                }

            }
            if (renderSide.right) {
                j = total + i;
                va = _varr[j + 1];
                vb = _varr[j];
                vc = _varr2[j];
                vd = _varr2[j + 1];
                _uva.u = _uvb.u = 1;
                _uvc.u = _uvd.u = 0;
                if (_flip) {
                    addFace(va, vb, vc, _uva, _uvb, _uvc, 3);
                    addFace(va, vc, vd, _uva, _uvc, _uvd, 3);
                }

                else {
                    addFace(vb, va, vc, _uvb, _uva, _uvc, 3);
                    addFace(vc, va, vd, _uvc, _uva, _uvd, 3);
                }

            }
            ++i;
        }
    }

    private function generate(vectors:Vector<Vector3D>, axis:String, tweek:Dynamic, render:Bool = true, id:Int = 0):Void {
// TODO: not used
        axis = axis;
        if (!tweek) tweek = { };
        if (Math.isNaN(tweek[X_AXIS]) || !tweek[X_AXIS]) tweek[X_AXIS] = 0;
        if (Math.isNaN(tweek[Y_AXIS]) || !tweek[Y_AXIS]) tweek[Y_AXIS] = 0;
        if (Math.isNaN(tweek[Z_AXIS]) || !tweek[Z_AXIS]) tweek[Z_AXIS] = 0;
        if (Math.isNaN(tweek["radius"]) || !tweek["radius"]) tweek["radius"] = 0;
        var angle:Float = _startRotationOffset;
        var step:Float = 360 / _subdivision;
        var j:Int;
        var tweekX:Float = 0;
        var tweekY:Float = 0;
        var tweekZ:Float = 0;
        var tweekradius:Float = 0;
        var tweekrotation:Float = 0;
        var tmpVecs:Vector<Vector3D>;
        var aRads:Array<Dynamic> = [];
        var uvu:Float;
        var uvv:Float;
        var i:Int;
        if (!_varr) _varr = new Vector<Vector3D>();
        i = 0;
        while (i < vectors.length) {
            _varr.push(new Vector3D(vectors[i].x, vectors[i].y, vectors[i].z));
            _uvarr.push(new UV(0, 1 % i));
            ++i;
        }
        var offsetradius:Float = -_offsetRadius;
        offsetradius += _prevOffsetRadius;
        var factor:Float = 0;
        var stepm:Float = 360 * _revolutions;
        var lsub:Float = ((_revolutions < 1)) ? _subdivision : _subdivision * _revolutions;
        if (_revolutions < 1) step *= _revolutions;
        i = 0;
        while (i <= lsub) {
            tmpVecs = new Vector<Vector3D>();
            tmpVecs = vectors.concat();
            j = 0;
            while (j < tmpVecs.length) {
                factor = ((_revolutions - 1) / (_varr.length + 1));
                if (tweek[X_AXIS] != 0) tweekX += (tweek[X_AXIS] * factor) / _revolutions;
                if (tweek[Y_AXIS] != 0) tweekY += (tweek[Y_AXIS] * factor) / _revolutions;
                if (tweek[Z_AXIS] != 0) tweekZ += (tweek[Z_AXIS] * factor) / _revolutions;
                if (tweek.radius != 0) tweekradius += (tweek.radius / (_varr.length + 1));
                if (tweek.rotation != 0) tweekrotation += 360 / (tweek.rotation * _subdivision);
                if (_axis == X_AXIS) {
                    if (i == 0) aRads[j] = offsetradius - Math.abs(tmpVecs[j].z);
                    tmpVecs[j].z = Math.cos(-angle / 180 * Math.PI) * (aRads[j] + tweekradius);
                    tmpVecs[j].y = Math.sin(angle / 180 * Math.PI) * (aRads[j] + tweekradius);
                    if (i == 0) {
                        _varr[j].z += tmpVecs[j].z;
                        _varr[j].y += tmpVecs[j].y;
                    }
                }

                else if (_axis == Y_AXIS) {
                    if (i == 0) aRads[j] = offsetradius - Math.abs(tmpVecs[j].x);
                    tmpVecs[j].x = Math.cos(-angle / 180 * Math.PI) * (aRads[j] + tweekradius);
                    tmpVecs[j].z = Math.sin(angle / 180 * Math.PI) * (aRads[j] + tweekradius);
                    if (i == 0) {
                        _varr[j].x = tmpVecs[j].x;
                        _varr[j].z = tmpVecs[j].z;
                    }
                }

                else {
                    if (i == 0) aRads[j] = offsetradius - Math.abs(tmpVecs[j].y);
                    tmpVecs[j].x = Math.cos(-angle / 180 * Math.PI) * (aRads[j] + tweekradius);
                    tmpVecs[j].y = Math.sin(angle / 180 * Math.PI) * (aRads[j] + tweekradius);
                    if (i == 0) {
                        _varr[j].x = tmpVecs[j].x;
                        _varr[j].y = tmpVecs[j].y;
                    }
                }

                tmpVecs[j].x += tweekX;
                tmpVecs[j].y += tweekY;
                tmpVecs[j].z += tweekZ;
                _varr.push(new Vector3D(tmpVecs[j].x, tmpVecs[j].y, tmpVecs[j].z));
                if (_coverAll) uvu = angle / stepm
                else uvu = ((i % 2 == 0)) ? 0 : 1;
                uvv = j / (_profile.length - 1);
                _uvarr.push(new UV(uvu, uvv));
                ++j;
            }
            angle += step;
            ++i;
        }
        _prevOffsetRadius = _offsetRadius;
        if (render) {
            var index:Int;
            var inc:Int = vectors.length;
            var loop:Int = _varr.length - inc;
            var va:Vector3D;
            var vb:Vector3D;
            var vc:Vector3D;
            var vd:Vector3D;
            var uva:UV;
            var uvb:UV;
            var uvc:UV;
            var uvd:UV;
            var uvind:Int;
            var vind:Int;
            var iter:Int = inc - 1;
            i = 0;
            while (i < loop) {
                index = 0;
                j = 0;
                while (j < iter) {
                    if (i > 0) {
                        uvind = i + index;
                        vind = uvind;
                        uva = _uvarr[uvind + 1];
                        uvb = _uvarr[uvind];
                        uvc = _uvarr[uvind + inc];
                        uvd = _uvarr[uvind + inc + 1];
                        if (_revolutions == 1 && i + inc == loop && _tweek == null) {
                            va = _varr[vind + 1];
                            vb = _varr[vind];
                            vc = _varr[vind + inc];
                            vd = _varr[vind + inc + 1];
                        }

                        else {
                            va = _varr[vind + 1];
                            vb = _varr[vind];
                            vc = _varr[vind + inc];
                            vd = _varr[vind + inc + 1];
                        }

                        if (_flip) {
                            if (id == 1) {
                                _uva.u = 1 - uva.u;
                                _uva.v = uva.v;
                                _uvb.u = 1 - uvb.u;
                                _uvb.v = uvb.v;
                                _uvc.u = 1 - uvc.u;
                                _uvc.v = uvc.v;
                                _uvd.u = 1 - uvd.u;
                                _uvd.v = uvd.v;
                                addFace(va, vb, vc, _uva, _uvb, _uvc, id);
                                addFace(va, vc, vd, _uva, _uvc, _uvd, id);
                            }

                            else {
                                addFace(vb, va, vc, uvb, uva, uvc, id);
                                addFace(vc, va, vd, uvc, uva, uvd, id);
                            }

                        }

                        else {
                            if (id == 1) {
                                _uva.u = uva.u;
                                _uva.v = 1 - uva.v;
                                _uvb.u = uvb.u;
                                _uvb.v = 1 - uvb.v;
                                _uvc.u = uvc.u;
                                _uvc.v = 1 - uvc.v;
                                _uvd.u = uvd.u;
                                _uvd.v = 1 - uvd.v;
                                addFace(vb, va, vc, _uvb, _uva, _uvc, id);
                                addFace(vc, va, vd, _uvc, _uva, _uvd, id);
                            }

                            else {
                                addFace(va, vb, vc, uva, uvb, uvc, id);
                                addFace(va, vc, vd, uva, uvc, uvd, id);
                            }

                        }

                    }
                    index++;
                    ++j;
                }
                i += inc;
            }
        }
    }

    private function buildExtrude():Void {
        if (!_profile) throw new Error("LatheExtrude error: No profile Vector.<Vector3D> set");
        _MaterialsSubGeometries = null;
        _geomDirty = false;
        initHolders();
        _maxIndProfile = _profile.length * 9;
        if (_profile.length > 1) {
            if (_thickness != 0) {
                var i:Int;
                var aListsides:Array<Dynamic> = ["top", "bottom", "right", "left", "front", "back"];
                var renderSide:RenderSide = new RenderSide();
                i = 0;
                while (i < aListsides.length) {
                    renderSide[aListsides[i]] = (_ignoreSides.indexOf(aListsides[i]) == -1);
                    ++i;
                }
                _varr = new Vector<Vector3D>();
                _varr2 = new Vector<Vector3D>();
                if (_preciseThickness) {
                    var prop1:String;
                    var prop2:String;
                    var prop3:String;
                    switch(_axis) {
                        case X_AXIS:
                            prop1 = X_AXIS;
                            prop2 = Z_AXIS;
                            prop3 = Y_AXIS;
                        case Y_AXIS:
                            prop1 = Y_AXIS;
                            prop2 = X_AXIS;
                            prop3 = Z_AXIS;
                        case Z_AXIS:
                            prop1 = Z_AXIS;
                            prop2 = Y_AXIS;
                            prop3 = X_AXIS;
                    }
                    var lines:Array<Dynamic> = buildThicknessPoints(_profile, thickness, prop1, prop2);
                    var points:FourPoints;
                    var vector:Vector3D;
                    var vector2:Vector3D;
                    var vector3:Vector3D;
                    var vector4:Vector3D;
                    var profileFront:Vector<Vector3D> = new Vector<Vector3D>();
                    var profileBack:Vector<Vector3D> = new Vector<Vector3D>();
                    i = 0;
                    while (i < lines.length) {
                        points = lines[i];
                        vector = new Vector3D();
                        vector2 = new Vector3D();
                        if (i == 0) {
                            vector[prop1] = points.pt2.x;
                            vector[prop2] = points.pt2.y;
                            vector[prop3] = _profile[0][prop3];
                            profileFront.push(vector);
                            vector2[prop1] = points.pt1.x;
                            vector2[prop2] = points.pt1.y;
                            vector2[prop3] = _profile[0][prop3];
                            profileBack.push(vector2);
                            if (lines.length == 1) {
                                vector3 = new Vector3D();
                                vector4 = new Vector3D();
                                vector3[prop1] = points.pt4.x;
                                vector3[prop2] = points.pt4.y;
                                vector3[prop3] = _profile[0][prop3];
                                profileFront.push(vector3);
                                vector4[prop1] = points.pt3.x;
                                vector4[prop2] = points.pt3.y;
                                vector4[prop3] = _profile[0][prop3];
                                profileBack.push(vector4);
                            }
                        }

                        else if (i == lines.length - 1) {
                            vector[prop1] = points.pt2.x;
                            vector[prop2] = points.pt2.y;
                            vector[prop3] = _profile[i][prop3];
                            profileFront.push(vector);
                            vector2[prop1] = points.pt1.x;
                            vector2[prop2] = points.pt1.y;
                            vector2[prop3] = _profile[i][prop3];
                            profileBack.push(vector2);
                            vector3 = new Vector3D();
                            vector4 = new Vector3D();
                            vector3[prop1] = points.pt4.x;
                            vector3[prop2] = points.pt4.y;
                            vector3[prop3] = _profile[i][prop3];
                            profileFront.push(vector3);
                            vector4[prop1] = points.pt3.x;
                            vector4[prop2] = points.pt3.y;
                            vector4[prop3] = _profile[i][prop3];
                            profileBack.push(vector4);
                        }

                        else {
                            vector[prop1] = points.pt2.x;
                            vector[prop2] = points.pt2.y;
                            vector[prop3] = _profile[i][prop3];
                            profileFront.push(vector);
                            vector2[prop1] = points.pt1.x;
                            vector2[prop2] = points.pt1.y;
                            vector2[prop3] = _profile[i][prop3];
                            profileBack.push(vector2);
                        }

                        ++i;
                    }
                    generate(profileFront, _axis, _tweek, renderSide.front, 0);
                    _varr2 = _varr2.concat(_varr);
                    _varr = new Vector<Vector3D>();
                    generate(profileBack, _axis, _tweek, renderSide.back, 1);
                }

                else {
// non distributed thickness
                    var tmprofile1:Vector<Vector3D> = new Vector<Vector3D>();
                    var tmprofile2:Vector<Vector3D> = new Vector<Vector3D>();
                    var halft:Float = _thickness * .5;
                    var val:Float;
                    i = 0;
                    while (i < _profile.length) {
                        switch(_axis) {
                            case X_AXIS:
                                val = ((_profile[i].z < 0)) ? halft : -halft;
                                tmprofile1.push(new Vector3D(_profile[i].x, _profile[i].y, _profile[i].z - val));
                                tmprofile2.push(new Vector3D(_profile[i].x, _profile[i].y, _profile[i].z + val));
                            case Y_AXIS:
                                val = ((_profile[i].x < 0)) ? halft : -halft;
                                tmprofile1.push(new Vector3D(_profile[i].x - val, _profile[i].y, _profile[i].z));
                                tmprofile2.push(new Vector3D(_profile[i].x + val, _profile[i].y, _profile[i].z));
                            case Z_AXIS:
                                val = ((_profile[i].y < 0)) ? halft : -halft;
                                tmprofile1.push(new Vector3D(_profile[i].x, _profile[i].y - val, _profile[i].z));
                                tmprofile2.push(new Vector3D(_profile[i].x, _profile[i].y + val, _profile[i].z));
                        }
                        ++i;
                    }
                    generate(tmprofile1, _axis, _tweek, renderSide.front, 0);
                    _varr2 = _varr2.concat(_varr);
                    _varr = new Vector<Vector3D>();
                    generate(tmprofile2, _axis, _tweek, renderSide.back, 1);
                }

                closeTopBottom(_profile.length, renderSide);
                if (_revolutions != 1) closeSides(_profile.length, renderSide);
            }

            else generate(_profile, _axis, _tweek);
        }

        else throw new Error("LatheExtrude error: the profile Vector.<Vector3D> must hold a mimimun of 2 vector3D's");
        if (_vertices.length > 0) {
            _subGeometry.updateVertexData(_vertices);
            _subGeometry.updateIndexData(_indices);
            _subGeometry.updateUVData(_uvs);
            if (_smoothSurface) _subGeometry.updateVertexNormalData(_normals);
            this.geometry.addSubGeometry(_subGeometry);
        }
        if (_MaterialsSubGeometries && _MaterialsSubGeometries.length > 0) {
            var sglist:SubGeometryList;
            var sg:SubGeometry;
            i = 1;
            while (i < 6) {
                sglist = _MaterialsSubGeometries[i];
                sg = sglist.subGeometry;
                if (sg && sglist.vertices.length > 0) {
                    this.geometry.addSubGeometry(sg);
                    this.subMeshes[this.subMeshes.length - 1].material = sglist.material;
                    sg.updateVertexData(sglist.vertices);
                    sg.updateIndexData(sglist.indices);
                    sg.updateUVData(sglist.uvs);
                    if (_smoothSurface) sg.updateVertexNormalData(sglist.normals);
                }
                ++i;
            }
        }
        if (_keepLastProfile) _lastProfile = _varr.splice(_varr.length - _profile.length, _profile.length)
        else _lastProfile = null;
        _varr = _varr2 = null;
        _uvarr = null;
        if (_centerMesh) MeshHelper.recenter(this);
    }

    private function calcNormal(v0:Vector3D, v1:Vector3D, v2:Vector3D):Void {
        var dx1:Float = v2.x - v0.x;
        var dy1:Float = v2.y - v0.y;
        var dz1:Float = v2.z - v0.z;
        var dx2:Float = v1.x - v0.x;
        var dy2:Float = v1.y - v0.y;
        var dz2:Float = v1.z - v0.z;
        var cx:Float = dz1 * dy2 - dy1 * dz2;
        var cy:Float = dx1 * dz2 - dz1 * dx2;
        var cz:Float = dy1 * dx2 - dx1 * dy2;
        var d:Float = 1 / Math.sqrt(cx * cx + cy * cy + cz * cz);
        _normal0.x = _normal1.x = _normal2.x = cx * d;
        _normal0.y = _normal1.y = _normal2.y = cy * d;
        _normal0.z = _normal1.z = _normal2.z = cz * d;
    }

    private function addFace(v0:Vector3D, v1:Vector3D, v2:Vector3D, uv0:UV, uv1:UV, uv2:UV, subGeomInd:Int):Void {
        var subGeom:SubGeometry;
        var uvs:Vector<Float>;
        var normals:Vector<Float>;
        var vertices:Vector<Float>;
        var indices:Vector<UInt>;
        if (subGeomInd > 0 && _MaterialsSubGeometries && _MaterialsSubGeometries.length > 0) {
            subGeom = _MaterialsSubGeometries[subGeomInd].subGeometry;
            uvs = _MaterialsSubGeometries[subGeomInd].uvs;
            vertices = _MaterialsSubGeometries[subGeomInd].vertices;
            indices = _MaterialsSubGeometries[subGeomInd].indices;
            normals = _MaterialsSubGeometries[subGeomInd].normals;
        }

        else {
            subGeom = _subGeometry;
            uvs = _uvs;
            vertices = _vertices;
            indices = _indices;
            normals = _normals;
        }

        if (vertices.length + 9 > LIMIT) {
            subGeom.updateVertexData(vertices);
            subGeom.updateIndexData(indices);
            subGeom.updateUVData(uvs);
            if (_smoothSurface) subGeom.updateVertexNormalData(normals);
            this.geometry.addSubGeometry(subGeom);
            if (subGeomInd > 0 && _MaterialsSubGeometries && _MaterialsSubGeometries[subGeomInd].subGeometry) this.subMeshes[this.subMeshes.length - 1].material = _MaterialsSubGeometries[subGeomInd].material;
            subGeom = new SubGeometry();
            subGeom.autoDeriveVertexTangents = true;
            if (_MaterialsSubGeometries && _MaterialsSubGeometries.length > 0) {
                _MaterialsSubGeometries[subGeomInd].subGeometry = subGeom;
                uvs = new Vector<Float>();
                vertices = new Vector<Float>();
                indices = new Vector<UInt>();
                normals = new Vector<Float>();
                _MaterialsSubGeometries[subGeomInd].uvs = uvs;
                _MaterialsSubGeometries[subGeomInd].indices = indices;
                if (_smoothSurface) _MaterialsSubGeometries[subGeomInd].normals = normals
                else subGeom.autoDeriveVertexNormals = true;
                if (subGeomInd == 0) {
                    _subGeometry = subGeom;
                    _uvs = uvs;
                    _vertices = vertices;
                    _indices = indices;
                    _normals = normals;
                }
            }

            else {
                _subGeometry = subGeom;
                _uvs = new Vector<Float>();
                _vertices = new Vector<Float>();
                _indices = new Vector<UInt>();
                _normals = new Vector<Float>();
                uvs = _uvs;
                vertices = _vertices;
                indices = _indices;
                normals = _normals;
            }

        }
        var bv0:Bool;
        var bv1:Bool;
        var bv2:Bool;
        var ind0:Int;
        var ind1:Int;
        var ind2:Int;
        if (_smoothSurface) {
            var uvind:Int;
            var uvindV:Int;
            var vind:Int;
            var vindy:Int;
            var vindz:Int;
            var ind:Int;
            var indlength:Int = indices.length;
            calcNormal(v0, v1, v2);
            var ab:Float;
            if (indlength > 0) {
                var back:Float = indlength - _maxIndProfile;
                var limitBack:Int = ((back < 0)) ? 0 : back;
                var i:Int = indlength - 1;
                while (i > limitBack) {
                    ind = indices[i];
                    vind = ind * 3;
                    vindy = vind + 1;
                    vindz = vind + 2;
                    uvind = ind * 2;
                    uvindV = uvind + 1;
                    if (bv0 && bv1 && bv2) break;
                    if (!bv0 && vertices[vind] == v0.x && vertices[vindy] == v0.y && vertices[vindz] == v0.z) {
                        _normalTmp.x = normals[vind];
                        _normalTmp.y = normals[vindy];
                        _normalTmp.z = normals[vindz];
                        ab = Vector3D.angleBetween(_normalTmp, _normal0);
                        if (ab < MAXRAD) {
                            _normal0.x = (_normalTmp.x + _normal0.x) * .5;
                            _normal0.y = (_normalTmp.y + _normal0.y) * .5;
                            _normal0.z = (_normalTmp.z + _normal0.z) * .5;
                            if (uvs[uvind] == uv0.u && uvs[uvindV] == uv0.v) {
                                bv0 = true;
                                ind0 = ind;
                                {
                                    --i;
                                    continue;
                                }

                            }
                        }
                    }
                    if (!bv1 && vertices[vind] == v1.x && vertices[vindy] == v1.y && vertices[vindz] == v1.z) {
                        _normalTmp.x = normals[vind];
                        _normalTmp.y = normals[vindy];
                        _normalTmp.z = normals[vindz];
                        ab = Vector3D.angleBetween(_normalTmp, _normal1);
                        if (ab < MAXRAD) {
                            _normal1.x = (_normalTmp.x + _normal1.x) * .5;
                            _normal1.y = (_normalTmp.y + _normal1.y) * .5;
                            _normal1.z = (_normalTmp.z + _normal1.z) * .5;
                            if (uvs[uvind] == uv1.u && uvs[uvindV] == uv1.v) {
                                bv1 = true;
                                ind1 = ind;
                                {
                                    --i;
                                    continue;
                                }

                            }
                        }
                    }
                    if (!bv2 && vertices[vind] == v2.x && vertices[vindy] == v2.y && vertices[vindz] == v2.z) {
                        _normalTmp.x = normals[vind];
                        _normalTmp.y = normals[vindy];
                        _normalTmp.z = normals[vindz];
                        ab = Vector3D.angleBetween(_normalTmp, _normal2);
                        if (ab < MAXRAD) {
                            _normal2.x = (_normalTmp.x + _normal2.x) * .5;
                            _normal2.y = (_normalTmp.y + _normal2.y) * .5;
                            _normal2.z = (_normalTmp.z + _normal2.z) * .5;
                            if (uvs[uvind] == uv2.u && uvs[uvindV] == uv2.v) {
                                bv2 = true;
                                ind2 = ind;
                                {
                                    --i;
                                    continue;
                                }

                            }
                        }
                    }
                    --i;
                }
            }
        }
        if (!bv0) {
            ind0 = vertices.length / 3;
            vertices.push(v0.x, v0.y, v0.z);
            uvs.push(uv0.u, uv0.v);
            if (_smoothSurface) normals.push(_normal0.x, _normal0.y, _normal0.z);
        }
        if (!bv1) {
            ind1 = vertices.length / 3;
            vertices.push(v1.x, v1.y, v1.z);
            uvs.push(uv1.u, uv1.v);
            if (_smoothSurface) normals.push(_normal1.x, _normal1.y, _normal1.z);
        }
        if (!bv2) {
            ind2 = vertices.length / 3;
            vertices.push(v2.x, v2.y, v2.z);
            uvs.push(uv2.u, uv2.v);
            if (_smoothSurface) normals.push(_normal2.x, _normal2.y, _normal2.z);
        }
        indices.push(ind0, ind1, ind2);
    }

    private function initHolders():Void {
        _uvarr = new Vector<UV>();
        _uva = new UV(0, 0);
        _uvb = new UV(0, 0);
        _uvc = new UV(0, 0);
        _uvd = new UV(0, 0);
        _va = new Vector3D(0, 0, 0);
        _vb = new Vector3D(0, 0, 0);
        _vc = new Vector3D(0, 0, 0);
        _vd = new Vector3D(0, 0, 0);
        _uvs = new Vector<Float>();
        _vertices = new Vector<Float>();
        _indices = new Vector<UInt>();
        _normals = new Vector<Float>();
        if (_smoothSurface) {
            _normal0 = new Vector3D(0.0, 0.0, 0.0);
            _normal1 = new Vector3D(0.0, 0.0, 0.0);
            _normal2 = new Vector3D(0.0, 0.0, 0.0);
            _normalTmp = new Vector3D(0.0, 0.0, 0.0);
        }

        else _subGeometry.autoDeriveVertexNormals = true;
        _subGeometry.autoDeriveVertexTangents = true;
        if (_materials && _thickness > 0) initSubGeometryList();
    }

    private function buildThicknessPoints(aPoints:Vector<Vector3D>, thickness:Float, prop1:String, prop2:String):Array<Dynamic> {
        var anchors:Array<Dynamic> = [];
        var lines:Array<Dynamic> = [];
        var i:Int;
        i = 0;
        while (i < aPoints.length - 1) {
            if (aPoints[i][prop1] == 0 && aPoints[i][prop2] == 0) aPoints[i][prop1] = EPS;
            if (aPoints[i + 1][prop2] != null && aPoints[i][prop2] == aPoints[i + 1][prop2]) aPoints[i + 1][prop2] += EPS;
            if (aPoints[i][prop1] != null && aPoints[i][prop1] == aPoints[i + 1][prop1]) aPoints[i + 1][prop1] += EPS;
            anchors.push(defineAnchors(aPoints[i], aPoints[i + 1], thickness, prop1, prop2));
            ++i;
        }
        var totallength:Int = anchors.length;
        var pointResult:FourPoints;
        if (totallength > 1) {
            i = 0;
            while (i < totallength) {
                if (i < totallength) pointResult = defineLines(i, anchors[i], anchors[i + 1], lines)
                else pointResult = defineLines(i, anchors[i], anchors[i - 1], lines);
                if (pointResult != null) lines.push(pointResult);
                ++i;
            }
        }

        else {
            var fourPoints:FourPoints = new FourPoints();
            var anchorFP:FourPoints = anchors[0];
            fourPoints.pt1 = anchorFP.pt1;
            fourPoints.pt2 = anchorFP.pt2;
            fourPoints.pt3 = anchorFP.pt3;
            fourPoints.pt4 = anchorFP.pt4;
            lines = [fourPoints];
        }

        return lines;
    }

    private function defineLines(index:Int, point1:FourPoints, point2:FourPoints = null, lines:Array<Dynamic> = null):FourPoints {
        var tmppt:FourPoints;
        var fourPoints:FourPoints = new FourPoints();
        if (point2 == null) {
            tmppt = lines[index - 1];
            fourPoints.pt1 = tmppt.pt3;
            fourPoints.pt2 = tmppt.pt4;
            fourPoints.pt3 = point1.pt3;
            fourPoints.pt4 = point1.pt4;
            return fourPoints;
        }
        var line1:Line = buildObjectLine(point1.pt1.x, point1.pt1.y, point1.pt3.x, point1.pt3.y);
        var line2:Line = buildObjectLine(point1.pt2.x, point1.pt2.y, point1.pt4.x, point1.pt4.y);
        var line3:Line = buildObjectLine(point2.pt1.x, point2.pt1.y, point2.pt3.x, point2.pt3.y);
        var line4:Line = buildObjectLine(point2.pt2.x, point2.pt2.y, point2.pt4.x, point2.pt4.y);
        var cross1:Point = lineIntersect(line3, line1);
        var cross2:Point = lineIntersect(line2, line4);
        if (cross1 != null && cross2 != null) {
            if (index == 0) {
                fourPoints.pt1 = point1.pt1;
                fourPoints.pt2 = point1.pt2;
                fourPoints.pt3 = cross1;
                fourPoints.pt4 = cross2;
                return fourPoints;
            }
            tmppt = lines[index - 1];
            fourPoints.pt1 = tmppt.pt3;
            fourPoints.pt2 = tmppt.pt4;
            fourPoints.pt3 = cross1;
            fourPoints.pt4 = cross2;
            return fourPoints;
        }

        else return null;
    }

    private function defineAnchors(base:Vector3D, baseEnd:Vector3D, thickness:Float, prop1:String, prop2:String):FourPoints {
        var angle:Float = (Math.atan2(base[prop2] - baseEnd[prop2], base[prop1] - baseEnd[prop1]) * 180) / Math.PI;
        angle -= 270;
        var angle2:Float = angle + 180;
        var fourPoints:FourPoints = new FourPoints();
        fourPoints.pt1 = new Point(base[prop1], base[prop2]);
        fourPoints.pt2 = new Point(base[prop1], base[prop2]);
        fourPoints.pt3 = new Point(baseEnd[prop1], baseEnd[prop2]);
        fourPoints.pt4 = new Point(baseEnd[prop1], baseEnd[prop2]);
        var radius:Float = thickness * .5;
        fourPoints.pt1.x = fourPoints.pt1.x + Math.cos(-angle / 180 * Math.PI) * radius;
        fourPoints.pt1.y = fourPoints.pt1.y + Math.sin(angle / 180 * Math.PI) * radius;
        fourPoints.pt2.x = fourPoints.pt2.x + Math.cos(-angle2 / 180 * Math.PI) * radius;
        fourPoints.pt2.y = fourPoints.pt2.y + Math.sin(angle2 / 180 * Math.PI) * radius;
        fourPoints.pt3.x = fourPoints.pt3.x + Math.cos(-angle / 180 * Math.PI) * radius;
        fourPoints.pt3.y = fourPoints.pt3.y + Math.sin(angle / 180 * Math.PI) * radius;
        fourPoints.pt4.x = fourPoints.pt4.x + Math.cos(-angle2 / 180 * Math.PI) * radius;
        fourPoints.pt4.y = fourPoints.pt4.y + Math.sin(angle2 / 180 * Math.PI) * radius;
        return fourPoints;
    }

    private function buildObjectLine(origX:Float, origY:Float, endX:Float, endY:Float):Line {
        var line:Line = new Line();
        line.ax = origX;
        line.ay = origY;
        line.bx = endX - origX;
        line.by = endY - origY;
        return line;
    }

    private function lineIntersect(Line1:Line, Line2:Line):Point {
        Line1.bx = ((Line1.bx == 0)) ? EPS : Line1.bx;
        Line2.bx = ((Line2.bx == 0)) ? EPS : Line2.bx;
        var a1:Float = Line1.by / Line1.bx;
        var b1:Float = Line1.ay - a1 * Line1.ax;
        var a2:Float = Line2.by / Line2.bx;
        var b2:Float = Line2.ay - a2 * Line2.ax;
        var nzero:Float = (((a1 - a2) == 0)) ? EPS : a1 - a2;
        var ptx:Float = (b2 - b1) / (nzero);
        var pty:Float = a1 * ptx + b1;
        if (isFinite(ptx) && isFinite(pty)) return new Point(ptx, pty)
        else {
            trace("infinity");
            return null;
        }

    }

/**
	 * Invalidates the geometry, causing it to be rebuilded when requested.
	 */

    private function invalidateGeometry():Void {
        _geomDirty = true;
        invalidateBounds();
    }

    private function initSubGeometryList():Void {
        var i:Int;
        var sglist:SubGeometryList;
        if (!_MaterialsSubGeometries) _MaterialsSubGeometries = new Vector<SubGeometryList>();
        i = 0;
        while (i < 6) {
            sglist = new SubGeometryList();
            _MaterialsSubGeometries.push(sglist);
            sglist.id = i;
            if (i == 0) {
                sglist.subGeometry = _subGeometry;
                sglist.uvs = _uvs;
                sglist.vertices = _vertices;
                sglist.indices = _indices;
                sglist.normals = _normals;
            }

            else {
                sglist.uvs = new Vector<Float>();
                sglist.vertices = new Vector<Float>();
                sglist.indices = new Vector<UInt>();
                sglist.normals = new Vector<Float>();
            }

            ++i;
        }
        var sg:SubGeometry;
        var prop:String;
        i = 1;
        while (i < 6) {
            switch(i) {
                case 1:
                    prop = "back";
                case 2:
                    prop = "left";
                case 3:
                    prop = "right";
                case 4:
                    prop = "top";
                case 5:
                    prop = "bottom";
                default:
                    prop = "front";
            }
            if (_materials[prop] && _MaterialsSubGeometries[i].subGeometry == null) {
                sglist = _MaterialsSubGeometries[i];
                sg = new SubGeometry();
                sglist.material = _materials[prop];
                sglist.subGeometry = sg;
                sg.autoDeriveVertexNormals = true;
                sg.autoDeriveVertexTangents = true;
            }
            ++i;
        }
    }

}
